import Foundation

/// Result of asking whether a button on a YouTube Page is a Skip Button.
public enum LabelMatch: Equatable {
    /// The visible text is a Skip Label. `label` is the normalised text that matched.
    case skipButton(label: String)
    /// YouTube marks the element as its skip button (class name), but the text is not a configured Skip Label.
    /// Diagnostic only: surfaced so the user can add the label to the config. Never pressed.
    case unrecognizedLabel(String)
    case none
}

/// Decides whether a button's visible text is a Skip Label.
public struct SkipButtonMatcher: Equatable {
    /// Class names YouTube has used on the skip button over the years.
    /// Secondary signal only: a class match without a label match is reported, not pressed.
    public static let knownClassNames: [String] = [
        "ytp-skip-ad-button",
        "ytp-ad-skip-button",
        "ytp-ad-skip-button-modern",
    ]

    private let labels: Set<String>

    public init(skipLabels: [String]) {
        labels = Set(skipLabels.map(Self.normalize).filter { !$0.isEmpty })
    }

    /// `label` and `description` are the two places WebKit exposes a button's name; either may match.
    public func match(label: String?, description: String?, classList: [String] = []) -> LabelMatch {
        let texts = [label, description]
            .compactMap { $0 }
            .map(Self.normalize)
            .filter { !$0.isEmpty }

        if let hit = texts.first(where: labels.contains) {
            return .skipButton(label: hit)
        }
        if classList.contains(where: Self.isKnownClassName) {
            return .unrecognizedLabel(texts.first ?? "")
        }
        return .none
    }

    /// Lower-cases, trims, and collapses runs of whitespace, so "  Skip  Ad " equals "skip ad".
    public static func normalize(_ text: String) -> String {
        text.lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func isKnownClassName(_ name: String) -> Bool {
        knownClassNames.contains { name.hasPrefix($0) }
    }
}
