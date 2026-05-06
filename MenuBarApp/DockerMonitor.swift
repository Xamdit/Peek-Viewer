import Foundation
import Combine
import AppKit

enum ContainerState: String, Codable {
    case running
    case exited
    case paused
    case restarting
    case removing
    case dead
    case created
    case unknown
}

struct DockerContainer: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var image: String
    var status: String
    var state: ContainerState
    var ports: String
    var workingDir: String?
}

struct DockerNetwork: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var driver: String
    var scope: String
}

struct DockerImage: Identifiable, Codable, Hashable {
    var id: String
    var repository: String
    var tag: String
    var size: String
    var created: String
    
    var name: String {
        return repository == "<none>" ? id : "\(repository):\(tag)"
    }
}

class DockerMonitor: ObservableObject {
    @Published var containers: [DockerContainer] = []
    @Published var networks: [DockerNetwork] = []
    @Published var images: [DockerImage] = []
    @Published var isDockerRunning: Bool = false
    
    private var timer: AnyCancellable?
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        fetchAll()
        
        // Refresh every 5 seconds
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchAll()
            }
    }
    
    func fetchAll() {
        fetchContainers()
        fetchNetworks()
        fetchImages()
    }
    
    func fetchContainers() {
        runDockerRaw(args: ["ps", "-a", "--format", "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.State}}|{{.Ports}}|{{.Label \"com.docker.compose.project.working_dir\"}}"]) { output in
            let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var newContainers: [DockerContainer] = []
            for line in lines {
                let parts = line.components(separatedBy: "|")
                if parts.count >= 7 {
                    let state = ContainerState(rawValue: parts[4]) ?? .unknown
                    let workingDir = parts[6].trimmingCharacters(in: .whitespaces)
                    newContainers.append(DockerContainer(
                        id: parts[0],
                        name: parts[1],
                        image: parts[2],
                        status: parts[3],
                        state: state,
                        ports: parts[5],
                        workingDir: workingDir.isEmpty ? nil : workingDir
                    ))
                }
            }
            DispatchQueue.main.async {
                self.containers = newContainers
                self.isDockerRunning = true
            }
        }
    }
    
    func fetchNetworks() {
        runDockerRaw(args: ["network", "ls", "--format", "{{.ID}}|{{.Name}}|{{.Driver}}|{{.Scope}}"]) { output in
            let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var newNetworks: [DockerNetwork] = []
            for line in lines {
                let parts = line.components(separatedBy: "|")
                if parts.count >= 4 {
                    newNetworks.append(DockerNetwork(id: parts[0], name: parts[1], driver: parts[2], scope: parts[3]))
                }
            }
            DispatchQueue.main.async { self.networks = newNetworks }
        }
    }
    
    func fetchImages() {
        runDockerRaw(args: ["images", "--format", "{{.ID}}|{{.Repository}}|{{.Tag}}|{{.Size}}|{{.CreatedAt}}"]) { output in
            let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var newImages: [DockerImage] = []
            for line in lines {
                let parts = line.components(separatedBy: "|")
                if parts.count >= 5 {
                    newImages.append(DockerImage(id: parts[0], repository: parts[1], tag: parts[2], size: parts[3], created: parts[4]))
                }
            }
            DispatchQueue.main.async { self.images = newImages }
        }
    }
    
    func fetchLogs(containerId: String, completion: @escaping (String) -> Void) {
        runDockerRaw(args: ["logs", "--tail", "100", containerId]) { output in
            DispatchQueue.main.async {
                completion(output)
            }
        }
    }
    
    private func runDockerRaw(args: [String], completion: @escaping (String) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        if !FileManager.default.fileExists(atPath: process.executableURL!.path) {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/docker")
        }
        if !FileManager.default.fileExists(atPath: process.executableURL!.path) {
             process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/docker")
        }
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                completion(output)
            }
        } catch {
            print("❌ Docker Raw Error: \(error.localizedDescription)")
            DispatchQueue.main.async { self.isDockerRunning = false }
        }
    }
    
    func toggleContainer(_ container: DockerContainer) {
        let command = container.state == .running ? "stop" : "start"
        runDockerCommand(command, args: [container.id])
    }
    
    func restartContainer(_ container: DockerContainer) {
        runDockerCommand("restart", args: [container.id])
    }

    func removeContainer(_ container: DockerContainer) {
        runDockerCommand("rm", args: ["-f", container.id])
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
            self.runDockerCommand("rmi", args: [container.image])
        }
    }
    
    func removeNetwork(_ network: DockerNetwork) {
        runDockerCommand("network", args: ["rm", network.id])
    }
    
    func removeImage(_ image: DockerImage) {
        runDockerCommand("rmi", args: ["-f", image.id])
    }
    
    private func runDockerCommand(_ command: String, containerId: String) {
        runDockerCommand(command, args: [containerId])
    }
    
    private func runDockerCommand(_ command: String, args: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        if !FileManager.default.fileExists(atPath: process.executableURL!.path) {
            process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/docker")
        }
        
        var finalArgs = [command]
        finalArgs.append(contentsOf: args)
        process.arguments = finalArgs
        
        do {
            try process.run()
            // Poll immediately after command
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchAll()
            }
        } catch {
            print("❌ Docker Command Error (\(command)): \(error.localizedDescription)")
        }
    }
}
