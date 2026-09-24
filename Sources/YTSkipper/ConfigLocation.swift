import Foundation
import SkipCore

/// Where the runtime config lives: `docs/config.json` in the repo the binary was built from.
/// `YTSKIPPER_CONFIG` overrides it, which is handy when running the bare binary from `swift run`.
enum ConfigLocation {
    static let relativePath = "docs/config.json"

    static func resolve(environment: [String: String] = ProcessInfo.processInfo.environment,
                        executable: URL? = Bundle.main.executableURL) -> URL? {
        if let override = environment["YTSKIPPER_CONFIG"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        guard let executable, let root = RepoRoot.locate(fromExecutable: executable) else {
            return nil
        }
        return root.appendingPathComponent(relativePath)
    }
}
