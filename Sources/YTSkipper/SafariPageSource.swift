import AppKit
import ApplicationServices
import os
import SkipCore

/// Looks at Safari through the Accessibility API.
///
/// Per Scan: list Safari's windows, read each window's document URL, and for the windows that show a
/// YouTube Page ask WebKit's search predicate for buttons whose text contains a Skip Label.
/// The predicate runs inside Safari's web process, so one round trip per label replaces a tree walk.
/// If the predicate is unavailable, a bounded walk of the web area is used instead.
final class SafariPageSource: PageSource {
    private let safariBundleIdentifier = "com.apple.Safari"
    private let messagingTimeoutSeconds: Float = 1.0
    private let webAreaSearchNodeLimit = 600
    private let fallbackWalkNodeLimit = 4000
    private let resultsPerLabel = 20
    private let log = Logger(subsystem: "com.github.kanataidarov.ytskipper", category: "safari")
    private var loggedPredicateFallback = false

    var isSafariRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: safariBundleIdentifier).isEmpty
    }

    func shownPages(searchTexts: [String], include: (URL?) -> Bool) -> [ShownPage] {
        guard let safari = NSRunningApplication.runningApplications(withBundleIdentifier: safariBundleIdentifier).first else {
            return []
        }
        let application = AXUIElementCreateApplication(safari.processIdentifier)
        AXUIElementSetMessagingTimeout(application, messagingTimeoutSeconds)

        guard let windows: [AXUIElement] = application.attribute(kAXWindowsAttribute) else { return [] }

        var pages: [ShownPage] = []
        for window in windows {
            var url = window.url("AXDocument")
            var webArea: AXUIElement?
            if url == nil {
                webArea = findWebArea(in: window)
                url = webArea?.url(kAXURLAttribute)
            }
            guard include(url) else { continue }

            if webArea == nil {
                webArea = findWebArea(in: window)
            }
            guard let area = webArea else {
                pages.append(ShownPage(url: url, buttons: []))
                continue
            }
            let buttons = findButtons(in: area, containing: searchTexts).map(candidate)
            pages.append(ShownPage(url: url, buttons: buttons))
        }
        return pages
    }

    // MARK: - Locating the web area

    /// Breadth-first search for the first `AXWebArea` under the window, bounded so a strange tree cannot stall a Scan.
    private func findWebArea(in window: AXUIElement) -> AXUIElement? {
        var queue: [AXUIElement] = [window]
        var visited = 0
        while !queue.isEmpty, visited < webAreaSearchNodeLimit {
            let element = queue.removeFirst()
            visited += 1
            if element.role == "AXWebArea" { return element }
            queue.append(contentsOf: element.children)
        }
        return nil
    }

    // MARK: - Finding buttons

    private func findButtons(in webArea: AXUIElement, containing texts: [String]) -> [AXUIElement] {
        var found: [AXUIElement] = []
        for text in texts {
            let parameter: [String: Any] = [
                "AXDirection": "AXDirectionNext",
                "AXImmediateDescendantsOnly": false,
                "AXResultsLimit": resultsPerLabel,
                "AXSearchKey": ["AXButtonSearchKey"],
                "AXSearchText": text,
                "AXVisibleOnly": false,
            ]
            let (error, elements): (AXError, [AXUIElement]?) = webArea.parameterizedAttribute(
                "AXUIElementsForSearchPredicate",
                parameter: parameter as CFDictionary
            )
            guard error == .success, let elements else {
                if !loggedPredicateFallback {
                    log.notice("Search predicate unavailable (AXError \(error.rawValue, privacy: .public)); walking the web area instead")
                    loggedPredicateFallback = true
                }
                return walkForButtons(in: webArea, containing: texts)
            }
            found.append(contentsOf: elements)
        }
        return found
    }

    /// Fallback: depth-first walk collecting buttons whose title or description contains one of `texts`.
    private func walkForButtons(in webArea: AXUIElement, containing texts: [String]) -> [AXUIElement] {
        let needles = texts.map { $0.lowercased() }.filter { !$0.isEmpty }
        var found: [AXUIElement] = []
        var stack: [AXUIElement] = [webArea]
        var visited = 0
        while let element = stack.popLast(), visited < fallbackWalkNodeLimit {
            visited += 1
            if element.role == kAXButtonRole as String {
                let text = [element.title, element.axDescription].compactMap { $0?.lowercased() }.joined(separator: " ")
                if needles.contains(where: text.contains) {
                    found.append(element)
                }
            }
            stack.append(contentsOf: element.children.reversed())
        }
        return found
    }

    private func candidate(_ element: AXUIElement) -> CandidateButton {
        CandidateButton(
            label: element.title,
            description: element.axDescription,
            classList: element.domClassList,
            frame: element.frame,
            press: { element.press() }
        )
    }
}
