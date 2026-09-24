import AppKit
import SkipCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var runner: ScanRunner?
    private var menu: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let runner = ScanRunner(configURL: ConfigLocation.resolve(), source: SafariPageSource())
        let menu = StatusMenuController(runner: runner)
        runner.onStateChange = { [weak menu] state in
            menu?.render(state)
        }
        self.runner = runner
        self.menu = menu
        runner.start()
    }
}
