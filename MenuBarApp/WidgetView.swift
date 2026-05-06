import SwiftUI
import AppKit

struct WidgetView: View {
    @ObservedObject var monitor: DockerMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Containers")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "shippingbox.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .padding(.bottom, 2)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if monitor.containers.isEmpty {
                        Text("No containers")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(monitor.containers) { container in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(container.state == .running ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: (container.state == .running ? Color.green : Color.red).opacity(0.5), radius: 1)
                                
                                Text(container.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(width: 180, height: 120)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        .cornerRadius(12)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
