import ApplicationServices
import Foundation

/// Thin, typed wrappers over the C accessibility API. Every call is one IPC round trip to Safari.
extension AXUIElement {
    func attribute<T>(_ name: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success, let value else {
            return nil
        }
        return value as? T
    }

    func parameterizedAttribute<T>(_ name: String, parameter: CFTypeRef) -> (AXError, T?) {
        var value: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(self, name as CFString, parameter, &value)
        guard error == .success, let value else { return (error, nil) }
        return (error, value as? T)
    }

    var role: String? {
        attribute(kAXRoleAttribute)
    }

    var title: String? {
        attribute(kAXTitleAttribute)
    }

    var axDescription: String? {
        attribute(kAXDescriptionAttribute)
    }

    var children: [AXUIElement] {
        attribute(kAXChildrenAttribute) ?? []
    }

    /// WebKit exposes the DOM `class` attribute of web content elements.
    var domClassList: [String] {
        attribute("AXDOMClassList") ?? []
    }

    /// Position and size in screen coordinates.
    var frame: CGRect {
        var rect = CGRect.zero
        if let position: AXValue = axValue(kAXPositionAttribute) {
            var point = CGPoint.zero
            if AXValueGetValue(position, .cgPoint, &point) { rect.origin = point }
        }
        if let size: AXValue = axValue(kAXSizeAttribute) {
            var value = CGSize.zero
            if AXValueGetValue(size, .cgSize, &value) { rect.size = value }
        }
        return rect
    }

    /// The document URL: Safari puts it on the window as `AXDocument`, WebKit on the web area as `AXURL`.
    func url(_ name: String) -> URL? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success, let value else {
            return nil
        }
        if CFGetTypeID(value) == CFURLGetTypeID() {
            return (value as! CFURL) as URL
        }
        if let string = value as? String {
            return URL(string: string)
        }
        return nil
    }

    func press() -> Bool {
        AXUIElementPerformAction(self, kAXPressAction as CFString) == .success
    }

    private func axValue(_ name: String) -> AXValue? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }
        return (value as! AXValue)
    }
}
