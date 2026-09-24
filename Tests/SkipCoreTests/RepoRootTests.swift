import Foundation
import Testing
@testable import SkipCore

@Suite struct RepoRootTests {
    private let marker = "YTSkipperTestMarker-\(UUID().uuidString)"

    private func makeTree() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ytskipper-root-\(UUID().uuidString)")
        let executable = root.appendingPathComponent("build/YTSkipper.app/Contents/MacOS/YTSkipper")
        try FileManager.default.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: executable)
        try Data().write(to: root.appendingPathComponent(marker))
        return root
    }

    @Test func findsTheRepoAboveTheAppBundle() throws {
        let root = try makeTree()
        let executable = root.appendingPathComponent("build/YTSkipper.app/Contents/MacOS/YTSkipper")
        let found = RepoRoot.locate(fromExecutable: executable, marker: marker)
        #expect(found?.resolvingSymlinksInPath().path == root.resolvingSymlinksInPath().path)
    }

    @Test func findsTheRepoAboveASwiftPMBuildFolder() throws {
        let root = try makeTree()
        let executable = root.appendingPathComponent(".build/arm64-apple-macosx/debug/YTSkipper")
        try FileManager.default.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: executable)
        let found = RepoRoot.locate(fromExecutable: executable, marker: marker)
        #expect(found?.resolvingSymlinksInPath().path == root.resolvingSymlinksInPath().path)
    }

    @Test func returnsNilWhenNoAncestorHasTheMarker() throws {
        let root = try makeTree()
        let executable = root.appendingPathComponent("build/YTSkipper.app/Contents/MacOS/YTSkipper")
        #expect(RepoRoot.locate(fromExecutable: executable, marker: "definitely-missing-\(UUID().uuidString)") == nil)
    }
}
