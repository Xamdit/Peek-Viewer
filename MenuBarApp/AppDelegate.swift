import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow?
    var widgetWindow: NSWindow?
    let dockerMonitor = DockerMonitor()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Peek: Application did finish launching")
        
        // Create the status item in the Menu Bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        updateIcon(color: .labelColor) // Default color
        
        setupMenu()
        
        // Automatically show widget on launch
        toggleWidget()
    }

    func setupMenu() {
        let menu = NSMenu()
        
        let dashboardItem = NSMenuItem(title: "Peek Dashboard", action: #selector(dashboardClicked), keyEquivalent: "d")
        menu.addItem(dashboardItem)
        
        let widgetItem = NSMenuItem(title: "Toggle Widget", action: #selector(toggleWidget), keyEquivalent: "w")
        menu.addItem(widgetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func toggleWidget() {
        if let existing = widgetWindow {
            existing.close()
            widgetWindow = nil
            return
        }
        
        let contentView = WidgetView(monitor: self.dockerMonitor)
        let window = PeekWidgetPanel(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        
        window.level = .mainMenu
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        
        // Initial position at top right
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 200
            let y = screenRect.maxY - 140
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.makeKeyAndOrderFront(nil)
        self.widgetWindow = window
    }
    
    func updateIcon(color: NSColor) {
        DispatchQueue.main.async {
            if let button = self.statusItem?.button {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                let image = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: "Docker Monitor")?
                    .withSymbolConfiguration(config)
                
                image?.isTemplate = true 
                button.image = image
            }
        }
    }

    @objc func dashboardClicked() {
        if window == nil {
            let contentView = DashboardView(monitor: self.dockerMonitor)
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 450),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window?.center()
            window?.setFrameAutosaveName("Dashboard Window")
            window?.contentView = NSHostingView(rootView: contentView)
            window?.title = "Peek Dashboard"
            window?.isReleasedWhenClosed = false
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: image.size)
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}

class PeekWidgetPanel: NSPanel {
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if event.clickCount == 2 {
            if let delegate = NSApp.delegate as? AppDelegate {
                delegate.dashboardClicked()
            }
        } else {
            snapToNearestCorner()
        }
    }
    
    func snapToNearestCorner() {
        guard let screen = self.screen ?? NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let windowRect = self.frame
        let margin: CGFloat = 20
        
        let centerX = windowRect.midX
        let centerY = windowRect.midY
        
        var targetX: CGFloat = 0
        var targetY: CGFloat = 0
        
        // Determine horizontal snap
        if centerX < screenRect.midX {
            targetX = screenRect.minX + margin
        } else {
            targetX = screenRect.maxX - windowRect.width - margin
        }
        
        // Determine vertical snap
        if centerY < screenRect.midY {
            targetY = screenRect.minY + margin
        } else {
            targetY = screenRect.maxY - windowRect.height - margin
        }
        
        let targetFrame = NSRect(x: targetX, y: targetY, width: windowRect.width, height: windowRect.height)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(targetFrame, display: true)
        }, completionHandler: nil)
    }
}
