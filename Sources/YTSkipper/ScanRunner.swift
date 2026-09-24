import Foundation
import os
import SkipCore

/// Drives Scans on a background queue at the agreed cadence and publishes state for the menu.
final class ScanRunner {
    struct State: Equatable {
        var enabled: Bool
        var trusted: Bool
        var skipCount: Int
        var watchingYouTubePage: Bool
        var configPath: String?
        var configProblem: String?
    }

    var onStateChange: ((State) -> Void)?

    private let queue = DispatchQueue(label: "com.github.kanataidarov.ytskipper.scan", qos: .utility)
    private let engine: SkipEngine
    private let store: ConfigStore?
    private let cadence = ScanCadence.default
    private let log = Logger(subsystem: "com.github.kanataidarov.ytskipper", category: "scan")
    private let defaults = UserDefaults.standard
    private let enabledKey = "enabled"

    private var enabled: Bool
    private var lastState: State?
    private var reportedUnrecognizedLabels: Set<String> = []

    init(configURL: URL?, source: PageSource) {
        engine = SkipEngine(source: source)
        store = configURL.map(ConfigStore.init(url:))
        enabled = defaults.object(forKey: enabledKey) as? Bool ?? true
        if configURL == nil {
            log.error("Could not locate the repo (no Package.swift above the executable); running with default config")
        }
    }

    func start() {
        Accessibility.promptIfNeeded()
        queue.async { [weak self] in
            guard let self else { return }
            // Create or read the config right away, before permission is granted, so it can be edited from the start.
            self.reloadConfigIfNeeded()
            self.log.notice("Config at \(self.store?.url.path ?? "<none>", privacy: .public)")
            self.tick()
        }
    }

    func setEnabled(_ value: Bool) {
        defaults.set(value, forKey: enabledKey)
        queue.async { [weak self] in
            guard let self else { return }
            self.enabled = value
            self.log.notice("Skipping \(value ? "enabled" : "disabled", privacy: .public)")
            self.publish(watching: false)
        }
    }

    // MARK: - Loop

    private func tick() {
        let trusted = Accessibility.isTrusted
        var sawYouTubePage = false

        if enabled && trusted {
            reloadConfigIfNeeded()
            let outcome = engine.scan()
            sawYouTubePage = outcome.sawYouTubePage
            report(outcome)
        }

        publish(watching: sawYouTubePage)
        let delay = cadence.interval(afterScanSawYouTubePage: sawYouTubePage && enabled && trusted)
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in self?.tick() }
    }

    private func reloadConfigIfNeeded() {
        guard let store else { return }
        if store.reloadIfChanged() {
            engine.config = store.config
            log.notice("Config reloaded: labels=\(store.config.skipLabels, privacy: .public) hosts=\(store.config.hosts, privacy: .public)")
        }
    }

    private func report(_ outcome: ScanOutcome) {
        if outcome.pressesSent > 0 {
            log.notice("Pressed \(outcome.pressesSent, privacy: .public) Skip Button(s)")
        }
        if outcome.skipsCompleted > 0 {
            log.notice("Skip completed; total \(self.engine.skipCount, privacy: .public)")
        }
        for label in outcome.unrecognizedLabels where !reportedUnrecognizedLabels.contains(label) {
            reportedUnrecognizedLabels.insert(label)
            log.notice("YouTube skip button with unrecognised label '\(label, privacy: .public)'. Add it to skipLabels in the config to press it.")
        }
    }

    private func publish(watching: Bool) {
        let state = State(
            enabled: enabled,
            trusted: Accessibility.isTrusted,
            skipCount: engine.skipCount,
            watchingYouTubePage: watching,
            configPath: store?.url.path,
            configProblem: configProblem()
        )
        guard state != lastState else { return }
        lastState = state
        DispatchQueue.main.async { [onStateChange] in onStateChange?(state) }
    }

    private func configProblem() -> String? {
        guard let store else { return "Config not found: run from the repo's build/ folder" }
        guard let error = store.lastError else { return nil }
        return "Config error: \(error.localizedDescription)"
    }
}
