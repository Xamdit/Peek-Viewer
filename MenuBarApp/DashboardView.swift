import SwiftUI

enum DockerViewType {
    case containers
    case networks
    case images
    case install
}

struct DashboardView: View {
    @StateObject var monitor: DockerMonitor
    @State private var viewType: DockerViewType = .containers
    
    @State private var selectedContainer: DockerContainer?
    @State private var selectedNetwork: DockerNetwork?
    @State private var selectedImage: DockerImage?
    
    @State private var itemToDelete: Any? = nil
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. Navigation Sidebar (Square Buttons)
            VStack(spacing: 15) {
                NavButton(icon: "shippingbox.fill", title: "Containers", isSelected: viewType == .containers) {
                    viewType = .containers
                }
                
                NavButton(icon: "network", title: "Networks", isSelected: viewType == .networks) {
                    viewType = .networks
                }
                
                NavButton(icon: "square.stack.3d.up.fill", title: "Images", isSelected: viewType == .images) {
                    viewType = .images
                }
                
                NavButton(icon: "arrow.down.circle.fill", title: "Install", isSelected: viewType == .install) {
                    viewType = .install
                }
                
                Spacer()
                
                Button(action: { monitor.fetchAll() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .padding(10)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh All")
            }
            .padding(.vertical, 20)
            .frame(width: 80)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 2. Middle Column & 3. Detail Column
            NavigationView {
                // Middle Column
                Group {
                    switch viewType {
                    case .containers:
                        ContainerListView(monitor: monitor, selectedContainer: $selectedContainer)
                    case .networks:
                        NetworkListView(monitor: monitor, selectedNetwork: $selectedNetwork)
                    case .images:
                        ImageListView(monitor: monitor, selectedImage: $selectedImage)
                    case .install:
                        InstallListView()
                    }
                }
                .frame(minWidth: 250)
                
                // Detail Column
                Group {
                    DetailRouterView(
                        monitor: monitor,
                        viewType: viewType,
                        container: selectedContainer,
                        network: selectedNetwork,
                        image: selectedImage,
                        itemToDelete: $itemToDelete,
                        showingDeleteConfirmation: $showingDeleteConfirmation
                    )
                }
            }
        }
        .frame(minWidth: 900, minHeight: 550)
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Confirm Deletion"),
                message: Text("Are you sure you want to delete this \(deleteItemTypeName())? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    performDelete()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func deleteItemTypeName() -> String {
        if itemToDelete is DockerContainer { return "container" }
        if itemToDelete is DockerNetwork { return "network" }
        if itemToDelete is DockerImage { return "image" }
        return "item"
    }
    
    private func performDelete() {
        if let container = itemToDelete as? DockerContainer {
            monitor.removeContainer(container)
            selectedContainer = nil
        } else if let network = itemToDelete as? DockerNetwork {
            monitor.removeNetwork(network)
            selectedNetwork = nil
        } else if let image = itemToDelete as? DockerImage {
            monitor.removeImage(image)
            selectedImage = nil
        }
    }
}

// MARK: - Navigation Components

struct NavButton: View {
    var icon: String
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 10))
            }
            .frame(width: 65, height: 65)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - List Views

struct ContainerListView: View {
    @ObservedObject var monitor: DockerMonitor
    @Binding var selectedContainer: DockerContainer?
    
    var body: some View {
        List(monitor.containers, selection: $selectedContainer) { container in
            HStack {
                StateIndicator(state: container.state)
                VStack(alignment: .leading) {
                    Text(container.name)
                        .fontWeight(.medium)
                    Text(container.image)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .tag(container)
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Containers")
    }
}

struct NetworkListView: View {
    @ObservedObject var monitor: DockerMonitor
    @Binding var selectedNetwork: DockerNetwork?
    
    var body: some View {
        List(monitor.networks, selection: $selectedNetwork) { network in
            VStack(alignment: .leading) {
                Text(network.name)
                    .fontWeight(.medium)
                Text(network.driver)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .tag(network)
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Networks")
    }
}

struct ImageListView: View {
    @ObservedObject var monitor: DockerMonitor
    @Binding var selectedImage: DockerImage?
    
    var body: some View {
        List(monitor.images, selection: $selectedImage) { image in
            VStack(alignment: .leading) {
                Text(image.repository)
                    .fontWeight(.medium)
                Text("Tag: \(image.tag) • \(image.size)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .tag(image)
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Images")
    }
}

struct InstallListView: View {
    var body: some View {
        List {
            HStack {
                Image(systemName: "terminal.fill")
                Text("Docker CLI Setup")
            }
            .padding(.vertical, 4)
            .tag(0)
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Install")
    }
}

// MARK: - Detail Views

struct DetailRouterView: View {
    @ObservedObject var monitor: DockerMonitor
    var viewType: DockerViewType
    var container: DockerContainer?
    var network: DockerNetwork?
    var image: DockerImage?
    
    @Binding var itemToDelete: Any?
    @Binding var showingDeleteConfirmation: Bool
    
    var body: some View {
        Group {
            switch viewType {
            case .containers:
                if let c = container, let latest = monitor.containers.first(where: { $0.id == c.id }) {
                    ContainerDetailView(monitor: monitor, container: latest, itemToDelete: $itemToDelete, showingDeleteConfirmation: $showingDeleteConfirmation)
                } else {
                    EmptyDetailView(icon: "shippingbox", text: "Select a container")
                }
            case .networks:
                if let n = network {
                    NetworkDetailView(monitor: monitor, network: n, itemToDelete: $itemToDelete, showingDeleteConfirmation: $showingDeleteConfirmation)
                } else {
                    EmptyDetailView(icon: "network", text: "Select a network")
                }
            case .images:
                if let i = image {
                    ImageDetailView(monitor: monitor, image: i, itemToDelete: $itemToDelete, showingDeleteConfirmation: $showingDeleteConfirmation)
                } else {
                    EmptyDetailView(icon: "square.stack.3d.up", text: "Select an image")
                }
            case .install:
                InstallDetailView(monitor: monitor)
            }
        }
    }
}

struct InstallDetailView: View {
    @ObservedObject var monitor: DockerMonitor
    @State private var isInstalling = false
    @State private var installLogs = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Tools Installation").font(.title).bold()
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: monitor.isDockerRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(monitor.isDockerRunning ? .green : .red)
                    Text(monitor.isDockerRunning ? "Docker tools are available" : "Docker CLI not detected in your PATH")
                        .fontWeight(.medium)
                }
                
                if !monitor.isDockerRunning {
                    Text("We can help you install the Docker CLI and Docker Compose using Homebrew. This will install the standard command-line tools.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: installDocker) {
                        if isInstalling {
                            HStack {
                                ProgressView().scaleEffect(0.5)
                                Text("Installing...")
                            }
                        } else {
                            Text("Install Docker & Compose via Brew")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                }
            }
            .padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            
            if !installLogs.isEmpty {
                ScrollView {
                    Text(installLogs)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black)
                .cornerRadius(8)
                .frame(maxHeight: 200)
            }
            
            Spacer()
        }
        .padding(30)
    }
    
    private func installDocker() {
        isInstalling = true
        installLogs = "Starting brew install docker docker-compose...\n"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        if !FileManager.default.fileExists(atPath: process.executableURL!.path) {
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/brew")
        }
        
        process.arguments = ["install", "docker", "docker-compose"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.installLogs += str
                    }
                }
            }
            
            process.terminationHandler = { _ in
                DispatchQueue.main.async {
                    self.isInstalling = false
                    self.installLogs += "\nInstallation finished."
                    self.monitor.fetchAll()
                }
            }
        } catch {
            isInstalling = false
            installLogs += "\nError: \(error.localizedDescription)"
        }
    }
}

struct EmptyDetailView: View {
    var icon: String
    var text: String
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
                .padding()
            Text(text)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Specific Details

struct ContainerDetailView: View {
    @ObservedObject var monitor: DockerMonitor
    var container: DockerContainer
    @Binding var itemToDelete: Any?
    @Binding var showingDeleteConfirmation: Bool
    
    @State private var logs: String = ""
    @State private var logTimer: Timer? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with Actions
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Text(container.name)
                            .font(.title)
                            .bold()
                        StateIndicator(state: container.state)
                    }
                    Text(container.id)
                        .font(.monospaced(.caption)())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions at the top
                HStack(spacing: 8) {
                    ActionButton(title: container.state == .running ? "Stop" : "Start",
                                 icon: container.state == .running ? "stop.fill" : "play.fill",
                                 color: container.state == .running ? .red : .green,
                                 isCompact: true) {
                        monitor.toggleContainer(container)
                    }
                    ActionButton(title: "Restart", icon: "arrow.clockwise", color: .orange, isCompact: true) {
                        monitor.restartContainer(container)
                    }
                    ActionButton(title: "Remove", icon: "trash.fill", color: .red, isCompact: true) {
                        itemToDelete = container
                        showingDeleteConfirmation = true
                    }
                    if let workingDir = container.workingDir {
                        ActionButton(title: "Show in Finder", icon: "folder.fill", color: .blue, isCompact: true) {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: URL(fileURLWithPath: workingDir).path)
                        }
                    }
                }
            }
            
            // Info Row
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    InfoRow(label: "Image", value: container.image)
                    Spacer()
                    InfoRow(label: "Status", value: container.status, valueColor: stateColor)
                }
                
                if !container.ports.isEmpty {
                    Divider().padding(.vertical, 2)
                    HStack(alignment: .top) {
                        Text("Ports").foregroundColor(.secondary).frame(width: 100, alignment: .leading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(parsePorts(container.ports), id: \.self) { port in
                                    Button(action: { if let url = URL(string: "http://localhost:\(port)") { NSWorkspace.shared.open(url) } }) {
                                        HStack(spacing: 4) {
                                            Text(port).fontWeight(.bold).underline()
                                            Image(systemName: "arrow.up.right.square").font(.caption2)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            
            // Activity Logs
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Activity Logs").font(.headline)
                    Spacer()
                    Button(action: { loadLogs() }) {
                        Image(systemName: "arrow.clockwise").font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Refresh Logs")
                }
                
                ScrollView {
                    Text(logs.isEmpty ? "Fetching logs..." : logs)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black)
                .cornerRadius(8)
                .frame(maxHeight: .infinity)
            }
        }
        .padding(30)
        .onAppear {
            loadLogs()
            startLogTimer()
        }
        .onDisappear {
            stopLogTimer()
        }
        .onChange(of: container.id) { _ in
            loadLogs()
        }
    }
    
    private func loadLogs() {
        monitor.fetchLogs(containerId: container.id) { output in
            self.logs = output
        }
    }
    
    private func startLogTimer() {
        logTimer?.invalidate()
        logTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            loadLogs()
        }
    }
    
    private func stopLogTimer() {
        logTimer?.invalidate()
        logTimer = nil
    }
    
    var stateColor: Color { container.state == .running ? .green : (container.state == .exited ? .red : .orange) }
    
    private func parsePorts(_ portsString: String) -> [String] {
        let parts = portsString.components(separatedBy: ",")
        var uniquePorts = Set<String>()
        for part in parts {
            let cleanPart = part.trimmingCharacters(in: .whitespaces)
            if let arrowRange = cleanPart.range(of: "->") {
                let hostSide = cleanPart[..<arrowRange.lowerBound]
                if let lastColonIndex = hostSide.lastIndex(of: ":") {
                    let port = String(hostSide[hostSide.index(after: lastColonIndex)...])
                    if !port.isEmpty { uniquePorts.insert(port) }
                }
            }
        }
        return Array(uniquePorts).sorted()
    }
}

struct NetworkDetailView: View {
    @ObservedObject var monitor: DockerMonitor
    var network: DockerNetwork
    @Binding var itemToDelete: Any?
    @Binding var showingDeleteConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text(network.name).font(.title).bold()
                Spacer()
                ActionButton(title: "Remove Network", icon: "trash.fill", color: .red, isCompact: true) {
                    itemToDelete = network
                    showingDeleteConfirmation = true
                }
            }
            
            VStack(alignment: .leading, spacing: 15) {
                InfoRow(label: "ID", value: network.id)
                InfoRow(label: "Driver", value: network.driver)
                InfoRow(label: "Scope", value: network.scope)
            }
            .padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            
            Spacer()
        }
        .padding(30)
    }
}

struct ImageDetailView: View {
    @ObservedObject var monitor: DockerMonitor
    var image: DockerImage
    @Binding var itemToDelete: Any?
    @Binding var showingDeleteConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text(image.repository).font(.title).bold()
                Spacer()
                ActionButton(title: "Remove Image", icon: "trash.fill", color: .red, isCompact: true) {
                    itemToDelete = image
                    showingDeleteConfirmation = true
                }
            }
            
            VStack(alignment: .leading, spacing: 15) {
                InfoRow(label: "ID", value: image.id)
                InfoRow(label: "Tag", value: image.tag)
                InfoRow(label: "Size", value: image.size)
                InfoRow(label: "Created", value: image.created)
            }
            .padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            
            Spacer()
        }
        .padding(30)
    }
}

// MARK: - Reusable Helpers

struct StateIndicator: View {
    var state: ContainerState
    var body: some View {
        Circle().fill(color).frame(width: 10, height: 10).shadow(color: color.opacity(0.5), radius: 2)
    }
    var color: Color {
        switch state {
        case .running: return .green
        case .paused: return .blue
        case .exited, .dead: return .red
        default: return .orange
        }
    }
}

struct InfoRow: View {
    var label: String
    var value: String
    var valueColor: Color = .primary
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary).frame(width: 100, alignment: .leading)
            Text(value).foregroundColor(valueColor).fontWeight(.medium).textSelection(.enabled)
            Spacer()
        }
    }
}

struct ActionButton: View {
    var title: String
    var icon: String
    var color: Color
    var isCompact: Bool = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if isCompact {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 28, height: 28)
                } else {
                    HStack {
                        Image(systemName: icon)
                        Text(title)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
            }
            .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .help(title)
    }
}
