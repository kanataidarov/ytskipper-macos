import Foundation

/// How hard to try on a Skip Button that does not go away.
public struct PressPolicy: Equatable {
    public var maxAttempts: Int
    public var retryInterval: TimeInterval

    public static let `default` = PressPolicy(maxAttempts: 3, retryInterval: 1.0)

    public init(maxAttempts: Int, retryInterval: TimeInterval) {
        self.maxAttempts = maxAttempts
        self.retryInterval = retryInterval
    }
}

/// Remembers which Skip Buttons have been pressed, spaces out retries, gives up after
/// `maxAttempts`, and counts a Skip when a pressed button is gone on a later Scan.
public struct PressTracker {
    private struct Record {
        var attempts: Int
        var lastAttempt: Date
    }

    public let policy: PressPolicy
    private var records: [ButtonKey: Record] = [:]

    public init(policy: PressPolicy = .default) {
        self.policy = policy
    }

    /// Call once per Scan, before deciding presses, with every Skip Button currently visible.
    /// Every remembered button that is no longer visible was pressed at least once, so it counts as a Skip.
    /// Returns the number of Skips.
    public mutating func reconcile(visible: Set<ButtonKey>) -> Int {
        let vanished = records.keys.filter { !visible.contains($0) }
        for key in vanished {
            records[key] = nil
        }
        return vanished.count
    }

    /// Whether `key` should be pressed now. Records the attempt when it returns true.
    public mutating func shouldPress(_ key: ButtonKey, now: Date) -> Bool {
        guard let record = records[key] else {
            records[key] = Record(attempts: 1, lastAttempt: now)
            return true
        }
        guard record.attempts < policy.maxAttempts,
              now.timeIntervalSince(record.lastAttempt) >= policy.retryInterval
        else {
            return false
        }
        records[key] = Record(attempts: record.attempts + 1, lastAttempt: now)
        return true
    }

    /// Presses recorded so far for `key`; zero when it has never been seen.
    public func attempts(for key: ButtonKey) -> Int {
        records[key]?.attempts ?? 0
    }
}
