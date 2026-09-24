import Testing
@testable import SkipCore

@Suite struct SkipButtonMatcherTests {
    let matcher = SkipButtonMatcher(skipLabels: SkipConfig.default.skipLabels)

    @Test func exactLabelIsASkipButton() {
        #expect(matcher.match(label: "Skip", description: nil) == .skipButton(label: "skip"))
        #expect(matcher.match(label: "Skip Ad", description: nil) == .skipButton(label: "skip ad"))
        #expect(matcher.match(label: "Skip Ads", description: nil) == .skipButton(label: "skip ads"))
    }

    @Test func matchIgnoresCaseAndWhitespace() {
        #expect(matcher.match(label: "  SKIP   AD\n", description: nil) == .skipButton(label: "skip ad"))
        #expect(matcher.match(label: "skip\u{00A0}ads", description: nil) == .skipButton(label: "skip ads"))
    }

    @Test func skipNavigationIsNotASkipButton() {
        #expect(matcher.match(label: "Skip navigation", description: nil) == .none)
        #expect(matcher.match(label: "Skip navigation", description: "Skip navigation") == .none)
    }

    @Test func descriptionCountsWhenTitleIsEmpty() {
        #expect(matcher.match(label: "", description: "Skip") == .skipButton(label: "skip"))
        #expect(matcher.match(label: nil, description: "Skip Ad") == .skipButton(label: "skip ad"))
    }

    @Test func knownClassWithUnknownLabelIsReportedNotMatched() {
        let result = matcher.match(label: "Пропустить", description: nil, classList: ["ytp-skip-ad-button"])
        #expect(result == .unrecognizedLabel("пропустить"))
    }

    @Test func knownClassPrefixIsRecognised() {
        let result = matcher.match(label: "Überspringen", description: nil, classList: ["ytp-ad-skip-button-modern"])
        #expect(result == .unrecognizedLabel("überspringen"))
    }

    @Test func classNameAloneNeverMakesASkipButton() {
        let result = matcher.match(label: "Anything", description: nil, classList: ["ytp-skip-ad-button"])
        if case .skipButton = result {
            Issue.record("class name must never be sufficient to press")
        }
    }

    @Test func unrelatedButtonIsNone() {
        #expect(matcher.match(label: "Subscribe", description: nil, classList: ["yt-spec-button-shape-next"]) == .none)
        #expect(matcher.match(label: nil, description: nil) == .none)
    }

    @Test func customLabelsReplaceDefaults() {
        let custom = SkipButtonMatcher(skipLabels: ["Пропустить"])
        #expect(custom.match(label: "пропустить", description: nil) == .skipButton(label: "пропустить"))
        #expect(custom.match(label: "Skip", description: nil) == .none)
    }

    @Test func normalizeCollapsesWhitespace() {
        #expect(SkipButtonMatcher.normalize("  Skip \t Ad  ") == "skip ad")
        #expect(SkipButtonMatcher.normalize("") == "")
    }
}
