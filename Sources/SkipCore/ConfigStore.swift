import Foundation

/// Owns the config file: writes defaults when it is missing, re-reads it when its
/// modification date changes, and keeps the last good config when the file is broken.
public final class ConfigStore {
    public let url: URL
    public private(set) var config: SkipConfig = .default
    /// Set when the file exists but could not be parsed; cleared on the next successful read.
    public private(set) var lastError: Error?

    private var lastModified: Date?

    public init(url: URL) {
        self.url = url
    }

    /// Creates the file with defaults if absent, then reloads it if it changed on disk.
    /// Returns true when the in-memory config changed as a result.
    @discardableResult
    public func reloadIfChanged() -> Bool {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try writeDefaults()
            } catch {
                lastError = error
                return false
            }
        }

        let modified = (try? fileManager.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        guard modified != lastModified else { return false }
        lastModified = modified

        do {
            let decoded = try JSONDecoder().decode(SkipConfig.self, from: Data(contentsOf: url))
            lastError = nil
            let changed = decoded != config
            config = decoded
            return changed
        } catch {
            lastError = error
            return false
        }
    }

    public func writeDefaults() throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(SkipConfig.default).write(to: url, options: .atomic)
    }
}
