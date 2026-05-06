import Cocoa

class Main {
    static let delegate = AppDelegate()
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = Main.delegate
app.run()
