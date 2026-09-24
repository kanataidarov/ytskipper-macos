import Foundation
import Testing
@testable import SkipCore

@Suite struct ConfigStoreTests {
    private func temporaryConfigURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ytskipper-tests-\(UUID().uuidString)")
            .appendingPathComponent("docs/config.json")
    }

    private func write(_ json: String, to url: URL, modifiedAt date: Date) throws {
        try Data(json.utf8).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }

    @Test func writesDefaultsWhenTheFileIsMissing() throws {
        let url = temporaryConfigURL()
        let store = ConfigStore(url: url)

        #expect(!store.reloadIfChanged())
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(store.config == .default)
        #expect(store.lastError == nil)

        let onDisk = try JSONDecoder().decode(SkipConfig.self, from: Data(contentsOf: url))
        #expect(onDisk == .default)
    }

    @Test func reloadsWhenTheFileChanges() throws {
        let url = temporaryConfigURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try write(#"{"hosts": ["localhost"]}"#, to: url, modifiedAt: Date(timeIntervalSince1970: 1_000))

        let store = ConfigStore(url: url)
        #expect(store.reloadIfChanged())
        #expect(store.config.hosts == ["localhost"])

        #expect(!store.reloadIfChanged(), "unchanged file must not report a change")

        try write(#"{"hosts": ["www.youtube.com"], "skipLabels": ["Skip"]}"#, to: url, modifiedAt: Date(timeIntervalSince1970: 2_000))
        #expect(store.reloadIfChanged())
        #expect(store.config == SkipConfig(skipLabels: ["Skip"], hosts: ["www.youtube.com"]))
    }

    @Test func keepsLastGoodConfigWhenTheFileIsBroken() throws {
        let url = temporaryConfigURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try write(#"{"hosts": ["localhost"]}"#, to: url, modifiedAt: Date(timeIntervalSince1970: 1_000))

        let store = ConfigStore(url: url)
        _ = store.reloadIfChanged()

        try write("{ broken", to: url, modifiedAt: Date(timeIntervalSince1970: 2_000))
        #expect(!store.reloadIfChanged())
        #expect(store.config.hosts == ["localhost"])
        #expect(store.lastError != nil)

        try write(#"{"hosts": ["music.youtube.com"]}"#, to: url, modifiedAt: Date(timeIntervalSince1970: 3_000))
        #expect(store.reloadIfChanged())
        #expect(store.lastError == nil)
        #expect(store.config.hosts == ["music.youtube.com"])
    }

    @Test func sameContentRewrittenIsNotAChange() throws {
        let url = temporaryConfigURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try write(#"{"hosts": ["localhost"]}"#, to: url, modifiedAt: Date(timeIntervalSince1970: 1_000))

        let store = ConfigStore(url: url)
        _ = store.reloadIfChanged()
        try write(#"{"hosts": ["localhost"]}"#, to: url, modifiedAt: Date(timeIntervalSince1970: 2_000))
        #expect(!store.reloadIfChanged())
    }
}
