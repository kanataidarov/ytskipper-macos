import AppKit

/// The menu bar item: ▶| icon, Enabled toggle, skip count, permission hint when needed, Quit.
final class StatusMenuController: NSObject {
    private let runner: ScanRunner
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let countItem = NSMenuItem(title: "Skipped: 0", action: nil, keyEquivalent: "")
    private let permissionItem = NSMenuItem(
        title: "Accessibility permission needed. Open System Settings…",
        action: #selector(openAccessibilitySettings),
        keyEquivalent: ""
    )
    private let configProblemItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit YTSkipper", action: #selector(quit), keyEquivalent: "q")

    init(runner: ScanRunner) {
        self.runner = runner
        super.init()

        for item in [enabledItem, permissionItem, quitItem] {
            item.target = self
        }
        countItem.isEnabled = false
        configProblemItem.isEnabled = false
        configProblemItem.isHidden = true
        permissionItem.isHidden = true

        menu.autoenablesItems = false
        menu.addItem(enabledItem)
        menu.addItem(countItem)
        menu.addItem(permissionItem)
        menu.addItem(configProblemItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "forward.end.fill", accessibilityDescription: "YTSkipper")
            button.image?.isTemplate = true
            button.toolTip = "YTSkipper"
        }
        statusItem.menu = menu
    }

    func render(_ state: ScanRunner.State) {
        enabledItem.state = state.enabled ? .on : .off
        countItem.title = "Skipped: \(state.skipCount)"
        permissionItem.isHidden = state.trusted
        configProblemItem.isHidden = state.configProblem == nil
        configProblemItem.title = state.configProblem ?? ""

        let active = state.enabled && state.trusted
        statusItem.button?.appearsDisabled = !active
        statusItem.button?.toolTip = tooltip(for: state)
    }

    private func tooltip(for state: ScanRunner.State) -> String {
        if !state.trusted { return "YTSkipper: waiting for Accessibility permission" }
        if !state.enabled { return "YTSkipper: disabled" }
        return state.watchingYouTubePage ? "YTSkipper: watching a YouTube page" : "YTSkipper: idle"
    }

    @objc private func toggleEnabled() {
        runner.setEnabled(enabledItem.state != .on)
    }

    @objc private func openAccessibilitySettings() {
        Accessibility.openSystemSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
