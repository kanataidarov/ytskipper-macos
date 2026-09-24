import Foundation

/// User-editable settings, read from `docs/config.json` in the repo.
///
/// Decoding is lenient: a missing or empty key falls back to its default, so a
/// half-edited file never silently disables the app.
public struct SkipConfig: Codable, Equatable {
    /// Exact visible texts that identify a Skip Button.
    /// Compared case-insensitively after whitespace normalisation; "Skip navigation" never matches "Skip".
    public var skipLabels: [String]

    /// Hosts whose shown pages are YouTube Pages. Exact, case-insensitive host match; no subdomain wildcards.
    public var hosts: [String]

    public static let `default` = SkipConfig(
        skipLabels: ["Skip", "Skip Ad", "Skip Ads"],
        hosts: ["www.youtube.com", "music.youtube.com"]
    )

    public init(skipLabels: [String], hosts: [String]) {
        self.skipLabels = skipLabels
        self.hosts = hosts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let labels = try container.decodeIfPresent([String].self, forKey: .skipLabels) ?? []
        let hosts = try container.decodeIfPresent([String].self, forKey: .hosts) ?? []
        self.skipLabels = labels.isEmpty ? Self.default.skipLabels : labels
        self.hosts = hosts.isEmpty ? Self.default.hosts : hosts
    }

    /// Whether `url` belongs to a YouTube Page.
    public func isYouTubePage(_ url: URL?) -> Bool {
        guard let host = url?.host?.lowercased(), !host.isEmpty else { return false }
        return hosts.contains { $0.lowercased() == host }
    }
}
