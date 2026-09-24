import Foundation
import Testing
@testable import SkipCore

@Suite struct PressTrackerTests {
    let key = ButtonKey(host: "www.youtube.com", label: "skip", frame: CGRect(x: 100, y: 200, width: 80, height: 30))
    let other = ButtonKey(host: "www.youtube.com", label: "skip", frame: CGRect(x: 500, y: 200, width: 80, height: 30))
    let t0 = Date(timeIntervalSinceReferenceDate: 1_000)

    /// `#expect` cannot call a mutating method inline, so decisions are collected first.
    private func decisions(_ tracker: inout PressTracker, _ key: ButtonKey, at offsets: [TimeInterval]) -> [Bool] {
        offsets.map { tracker.shouldPress(key, now: t0.addingTimeInterval($0)) }
    }

    @Test func firstSightingIsPressed() {
        var tracker = PressTracker()
        let pressed = tracker.shouldPress(key, now: t0)
        #expect(pressed)
        #expect(tracker.attempts(for: key) == 1)
    }

    @Test func noRetryBeforeIntervalElapses() {
        var tracker = PressTracker()
        let results = decisions(&tracker, key, at: [0, 0.5, 0.99])
        #expect(results == [true, false, false])
        #expect(tracker.attempts(for: key) == 1)
    }

    @Test func retriesAfterIntervalUpToMaxAttempts() {
        var tracker = PressTracker(policy: PressPolicy(maxAttempts: 3, retryInterval: 1.0))
        let results = decisions(&tracker, key, at: [0, 1, 2, 3, 60])
        #expect(results == [true, true, true, false, false])
        #expect(tracker.attempts(for: key) == 3)
    }

    @Test func vanishedPressedButtonCountsAsSkip() {
        var tracker = PressTracker()
        _ = tracker.shouldPress(key, now: t0)
        let skips = tracker.reconcile(visible: [])
        #expect(skips == 1)
        #expect(tracker.attempts(for: key) == 0)
    }

    @Test func stillVisibleButtonIsNotASkip() {
        var tracker = PressTracker()
        _ = tracker.shouldPress(key, now: t0)
        let skips = tracker.reconcile(visible: [key])
        #expect(skips == 0)
        #expect(tracker.attempts(for: key) == 1)
    }

    @Test func neverPressedButtonsAreNotSkips() {
        var tracker = PressTracker()
        let whileVisible = tracker.reconcile(visible: [key, other])
        let afterVanishing = tracker.reconcile(visible: [])
        #expect(whileVisible == 0)
        #expect(afterVanishing == 0)
    }

    @Test func buttonsAreTrackedIndependently() {
        var tracker = PressTracker()
        _ = tracker.shouldPress(key, now: t0)
        let otherPressed = tracker.shouldPress(other, now: t0)
        let skips = tracker.reconcile(visible: [other])
        #expect(otherPressed)
        #expect(skips == 1)
        #expect(tracker.attempts(for: other) == 1)
        #expect(tracker.attempts(for: key) == 0)
    }

    @Test func reappearingButtonStartsFresh() {
        var tracker = PressTracker(policy: PressPolicy(maxAttempts: 1, retryInterval: 1.0))
        let first = decisions(&tracker, key, at: [0, 5])
        _ = tracker.reconcile(visible: [])
        let again = tracker.shouldPress(key, now: t0.addingTimeInterval(10))
        #expect(first == [true, false])
        #expect(again)
    }

    @Test func keyRoundsFramesToWholePoints() {
        let a = ButtonKey(host: "h", label: "skip", frame: CGRect(x: 10.2, y: 20.4, width: 80.1, height: 30.3))
        let b = ButtonKey(host: "h", label: "skip", frame: CGRect(x: 10, y: 20, width: 80, height: 30))
        #expect(a == b)
        #expect(a != ButtonKey(host: "h", label: "skip ad", frame: CGRect(x: 10, y: 20, width: 80, height: 30)))
    }
}
