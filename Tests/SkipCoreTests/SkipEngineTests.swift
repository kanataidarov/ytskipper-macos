import Foundation
import Testing
@testable import SkipCore

/// A page source with fixed pages; records what the engine asked for and which buttons were pressed.
final class FakePageSource: PageSource {
    var pages: [ShownPage] = []
    var lastSearchTexts: [String] = []
    var presses: [String] = []
    var pressSucceeds = true

    func shownPages(searchTexts: [String], include: (URL?) -> Bool) -> [ShownPage] {
        lastSearchTexts = searchTexts
        return pages.filter { include($0.url) }
    }

    func button(_ label: String, x: CGFloat = 0, classList: [String] = []) -> CandidateButton {
        CandidateButton(label: label, description: nil, classList: classList, frame: CGRect(x: x, y: 0, width: 80, height: 30)) {
            self.presses.append(label)
            return self.pressSucceeds
        }
    }
}

@Suite struct SkipEngineTests {
    let youtube = URL(string: "https://www.youtube.com/watch?v=abc")!
    let t0 = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func pressesSkipButtonOnYouTubePageAndCountsSkipWhenItVanishes() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source)
        source.pages = [ShownPage(url: youtube, buttons: [source.button("Skip")])]

        let first = engine.scan(now: t0)
        #expect(first.sawYouTubePage)
        #expect(first.skipButtonsSeen == 1)
        #expect(first.pressesSent == 1)
        #expect(first.skipsCompleted == 0)
        #expect(source.presses == ["Skip"])
        #expect(engine.skipCount == 0)

        source.pages = [ShownPage(url: youtube, buttons: [])]
        let second = engine.scan(now: t0.addingTimeInterval(0.5))
        #expect(second.skipsCompleted == 1)
        #expect(second.pressesSent == 0)
        #expect(engine.skipCount == 1)
    }

    @Test func searchesForTheConfiguredLabels() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source, config: SkipConfig(skipLabels: ["Skip", "Пропустить"], hosts: ["www.youtube.com"]))
        engine.scan(now: t0)
        #expect(source.lastSearchTexts == ["Skip", "Пропустить"])
    }

    @Test func ignoresPagesThatAreNotYouTubePages() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source)
        source.pages = [ShownPage(url: URL(string: "https://example.com/")!, buttons: [source.button("Skip")])]

        let outcome = engine.scan(now: t0)
        #expect(!outcome.sawYouTubePage)
        #expect(outcome.pressesSent == 0)
        #expect(source.presses.isEmpty)
    }

    @Test func neverPressesSkipNavigation() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source)
        source.pages = [ShownPage(url: youtube, buttons: [source.button("Skip navigation")])]

        let outcome = engine.scan(now: t0)
        #expect(outcome.sawYouTubePage)
        #expect(outcome.skipButtonsSeen == 0)
        #expect(source.presses.isEmpty)
    }

    @Test func givesUpOnAStubbornButtonAfterThreeAttempts() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source)
        source.pages = [ShownPage(url: youtube, buttons: [source.button("Skip Ad")])]

        for i in 0..<12 {
            engine.scan(now: t0.addingTimeInterval(Double(i) * 0.5))
        }
        #expect(source.presses.count == 3)
        #expect(engine.skipCount == 0)
    }

    @Test func failedPressStillCountsAsAnAttempt() {
        let source = FakePageSource()
        source.pressSucceeds = false
        let engine = SkipEngine(source: source)
        source.pages = [ShownPage(url: youtube, buttons: [source.button("Skip")])]

        engine.scan(now: t0)
        let again = engine.scan(now: t0.addingTimeInterval(0.2))
        #expect(again.pressesSent == 0)
    }

    @Test func reportsUnrecognizedLabelsWithoutPressing() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source)
        source.pages = [ShownPage(url: youtube, buttons: [source.button("Пропустить", classList: ["ytp-skip-ad-button"])])]

        let outcome = engine.scan(now: t0)
        #expect(outcome.unrecognizedLabels == ["пропустить"])
        #expect(outcome.pressesSent == 0)
    }

    @Test func configChangeTakesEffectOnNextScan() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source)
        source.pages = [ShownPage(url: youtube, buttons: [source.button("Пропустить")])]

        #expect(engine.scan(now: t0).pressesSent == 0)
        engine.config = SkipConfig(skipLabels: ["Пропустить"], hosts: ["www.youtube.com"])
        #expect(engine.scan(now: t0.addingTimeInterval(0.5)).pressesSent == 1)
    }

    @Test func twoWindowsWithSkipButtonsAreBothPressed() {
        let source = FakePageSource()
        let engine = SkipEngine(source: source)
        source.pages = [
            ShownPage(url: youtube, buttons: [source.button("Skip", x: 10)]),
            ShownPage(url: URL(string: "https://music.youtube.com/")!, buttons: [source.button("Skip", x: 10)]),
        ]

        let outcome = engine.scan(now: t0)
        #expect(outcome.skipButtonsSeen == 2)
        #expect(outcome.pressesSent == 2)
    }

    @Test func noPagesMeansIdle() {
        let engine = SkipEngine(source: FakePageSource())
        #expect(engine.scan(now: t0) == ScanOutcome())
    }
}
