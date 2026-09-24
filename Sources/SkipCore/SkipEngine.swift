import Foundation

/// What one Scan found and did.
public struct ScanOutcome: Equatable {
    public var sawYouTubePage = false
    public var skipButtonsSeen = 0
    public var pressesSent = 0
    public var skipsCompleted = 0
    /// Texts of elements YouTube marks as skip buttons whose label is not a configured Skip Label.
    public var unrecognizedLabels: [String] = []

    public init() {}
}

/// Runs Scans: asks the page source for candidate buttons on YouTube Pages, recognises Skip Buttons
/// by their Skip Labels, presses them under the retry policy, and counts Skips.
public final class SkipEngine {
    public private(set) var skipCount = 0

    public var config: SkipConfig {
        didSet { matcher = SkipButtonMatcher(skipLabels: config.skipLabels) }
    }

    private let source: PageSource
    private var matcher: SkipButtonMatcher
    private var tracker: PressTracker

    public init(source: PageSource, config: SkipConfig = .default, policy: PressPolicy = .default) {
        self.source = source
        self.config = config
        self.matcher = SkipButtonMatcher(skipLabels: config.skipLabels)
        self.tracker = PressTracker(policy: policy)
    }

    @discardableResult
    public func scan(now: Date = Date()) -> ScanOutcome {
        var outcome = ScanOutcome()
        let pages = source.shownPages(searchTexts: config.skipLabels, include: config.isYouTubePage)
        outcome.sawYouTubePage = !pages.isEmpty

        var visible: [(key: ButtonKey, button: CandidateButton)] = []
        for page in pages {
            let host = page.url?.host?.lowercased() ?? ""
            for button in page.buttons {
                switch matcher.match(label: button.label, description: button.description, classList: button.classList) {
                case .skipButton(let label):
                    visible.append((ButtonKey(host: host, label: label, frame: button.frame), button))
                case .unrecognizedLabel(let text):
                    outcome.unrecognizedLabels.append(text)
                case .none:
                    break
                }
            }
        }
        outcome.skipButtonsSeen = visible.count

        outcome.skipsCompleted = tracker.reconcile(visible: Set(visible.map(\.key)))
        skipCount += outcome.skipsCompleted

        for (key, button) in visible where tracker.shouldPress(key, now: now) {
            // A failed press still counts as an attempt; the policy schedules the retry.
            _ = button.press()
            outcome.pressesSent += 1
        }
        return outcome
    }
}
