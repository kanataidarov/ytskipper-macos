import Foundation

/// Finds the repo the running binary belongs to. Everything the app needs at runtime lives there.
public enum RepoRoot {
    /// Nearest ancestor directory of `executable` that contains `marker`, or nil.
    /// Works for `build/YTSkipper.app/Contents/MacOS/YTSkipper` and for `.build/<triple>/debug/YTSkipper` alike.
    public static func locate(fromExecutable executable: URL, marker: String = "Package.swift") -> URL? {
        var directory = executable.resolvingSymlinksInPath().deletingLastPathComponent()
        while true {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent(marker).path) {
                return directory
            }
            let parent = directory.deletingLastPathComponent()
            if parent.path == directory.path { return nil }
            directory = parent
        }
    }
}
