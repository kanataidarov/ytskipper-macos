import Foundation

/// How long to wait between Scans.
public struct ScanCadence: Equatable {
    /// Used while at least one Safari window shows a YouTube Page.
    public var activeInterval: TimeInterval
    /// Used otherwise, just often enough to notice when a YouTube Page appears.
    public var idleInterval: TimeInterval

    public static let `default` = ScanCadence(activeInterval: 0.5, idleInterval: 2.0)

    public init(activeInterval: TimeInterval, idleInterval: TimeInterval) {
        self.activeInterval = activeInterval
        self.idleInterval = idleInterval
    }

    public func interval(afterScanSawYouTubePage saw: Bool) -> TimeInterval {
        saw ? activeInterval : idleInterval
    }
}
