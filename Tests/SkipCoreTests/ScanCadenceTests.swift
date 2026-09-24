import Testing
@testable import SkipCore

@Suite struct ScanCadenceTests {
    @Test func defaultsMatchTheAgreedNumbers() {
        #expect(ScanCadence.default.activeInterval == 0.5)
        #expect(ScanCadence.default.idleInterval == 2.0)
    }

    @Test func activeWhileAYouTubePageIsShown() {
        let cadence = ScanCadence(activeInterval: 0.25, idleInterval: 3)
        #expect(cadence.interval(afterScanSawYouTubePage: true) == 0.25)
        #expect(cadence.interval(afterScanSawYouTubePage: false) == 3)
    }
}
