import AppKit

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
// Menu bar only: no Dock icon, no main window. Info.plist sets LSUIElement as well.
application.setActivationPolicy(.accessory)
application.run()
