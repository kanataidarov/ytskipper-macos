import Foundation
import Testing
@testable import SkipCore

@Suite struct SkipConfigTests {
    let config = SkipConfig.default

    @Test func defaultHostsAreYouTubePages() {
        #expect(config.isYouTubePage(URL(string: "https://www.youtube.com/watch?v=abc")))
        #expect(config.isYouTubePage(URL(string: "https://music.youtube.com/watch?v=abc")))
    }

    @Test func hostMatchIsExactAndCaseInsensitive() {
        #expect(config.isYouTubePage(URL(string: "https://WWW.YouTube.com/")))
        #expect(!config.isYouTubePage(URL(string: "https://youtube.com/")))
        #expect(!config.isYouTubePage(URL(string: "https://m.youtube.com/")))
        #expect(!config.isYouTubePage(URL(string: "https://www.youtube.com.evil.example/")))
    }

    @Test func otherSitesAndMissingURLsAreNotYouTubePages() {
        #expect(!config.isYouTubePage(URL(string: "https://example.com/embed")))
        #expect(!config.isYouTubePage(URL(string: "file:///Users/me/page.html")))
        #expect(!config.isYouTubePage(nil))
    }

    @Test func configuredLocalhostBecomesAYouTubePage() {
        let local = SkipConfig(skipLabels: ["Skip"], hosts: ["localhost"])
        #expect(local.isYouTubePage(URL(string: "http://localhost:8765/skip-page.html")))
        #expect(!local.isYouTubePage(URL(string: "https://www.youtube.com/")))
    }

    @Test func decodesFullFile() throws {
        let json = #"{"skipLabels": ["Skip", "Пропустить"], "hosts": ["www.youtube.com"]}"#
        let decoded = try JSONDecoder().decode(SkipConfig.self, from: Data(json.utf8))
        #expect(decoded == SkipConfig(skipLabels: ["Skip", "Пропустить"], hosts: ["www.youtube.com"]))
    }

    @Test func missingOrEmptyKeysFallBackToDefaults() throws {
        let missing = try JSONDecoder().decode(SkipConfig.self, from: Data("{}".utf8))
        #expect(missing == .default)

        let empty = try JSONDecoder().decode(SkipConfig.self, from: Data(#"{"skipLabels": [], "hosts": []}"#.utf8))
        #expect(empty == .default)

        let onlyHosts = try JSONDecoder().decode(SkipConfig.self, from: Data(#"{"hosts": ["localhost"]}"#.utf8))
        #expect(onlyHosts.hosts == ["localhost"])
        #expect(onlyHosts.skipLabels == SkipConfig.default.skipLabels)
    }

    @Test func unknownKeysAreIgnored() throws {
        let decoded = try JSONDecoder().decode(SkipConfig.self, from: Data(#"{"comment": "hi", "hosts": ["a"]}"#.utf8))
        #expect(decoded.hosts == ["a"])
    }

    @Test func malformedJSONThrows() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(SkipConfig.self, from: Data("{not json".utf8))
        }
    }

    @Test func roundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SkipConfig.self, from: data)
        #expect(decoded == config)
    }
}
