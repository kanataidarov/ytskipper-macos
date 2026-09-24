// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YTSkipper",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure decision logic: labels, hosts, cadence, press/retry tracking. No AppKit, no AX.
        .target(
            name: "SkipCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Menu bar app: Safari accessibility access, status item, scan loop.
        .executableTarget(
            name: "YTSkipper",
            dependencies: ["SkipCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SkipCoreTests",
            dependencies: ["SkipCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
