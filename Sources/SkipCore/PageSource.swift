import Foundation
import CoreGraphics

/// Identity of a Skip Button across Scans, built from what stays stable while it is on screen.
/// Accessibility element references are not guaranteed to compare equal between scans, so this is used instead.
public struct ButtonKey: Hashable {
    public let host: String
    public let label: String
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int

    public init(host: String, label: String, frame: CGRect) {
        self.host = host
        self.label = label
        x = Int(frame.origin.x.rounded())
        y = Int(frame.origin.y.rounded())
        width = Int(frame.size.width.rounded())
        height = Int(frame.size.height.rounded())
    }
}

/// A button found on a shown page, with a way to press it.
public struct CandidateButton {
    public let label: String?
    public let description: String?
    public let classList: [String]
    public let frame: CGRect
    /// Presses the button. Returns false when the press could not be delivered.
    public let press: () -> Bool

    public init(label: String?, description: String?, classList: [String] = [], frame: CGRect, press: @escaping () -> Bool) {
        self.label = label
        self.description = description
        self.classList = classList
        self.frame = frame
        self.press = press
    }
}

/// The web content one Safari window currently shows.
public struct ShownPage {
    public let url: URL?
    public let buttons: [CandidateButton]

    public init(url: URL?, buttons: [CandidateButton]) {
        self.url = url
        self.buttons = buttons
    }
}

/// Something that can look at what Safari shows.
/// The app implements it with the Accessibility API; tests implement it with fixed data.
public protocol PageSource {
    /// Shown pages for which `include(url)` is true, each with the buttons whose visible text
    /// contains any of `searchTexts` (case-insensitive). Pages not included are not searched.
    func shownPages(searchTexts: [String], include: (URL?) -> Bool) -> [ShownPage]
}
