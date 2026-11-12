import AppKit
import ApplicationServices

@MainActor
enum WindowController {
    static func capture() -> [SavedWindow] {
        guard AXIsProcessTrusted() else { return [] }
        return NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated && $0.activationPolicy == .regular }
            .flatMap { app -> [SavedWindow] in
                guard let identifier = app.bundleIdentifier else { return [] }
                let appElement = AXUIElementCreateApplication(app.processIdentifier)
                var value: CFTypeRef?
                guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value) == .success,
                      let windows = value as? [AXUIElement] else { return [] }
                return windows.compactMap { window in
                    guard let frame = frame(of: window), frame.width > 80, frame.height > 60 else { return nil }
                    return SavedWindow(bundleIdentifier: identifier, title: title(of: window),
                                       x: frame.minX, y: frame.minY, width: frame.width, height: frame.height)
                }
            }
    }

    @discardableResult
    static func restore(_ windows: [SavedWindow]) -> Int {
        guard AXIsProcessTrusted() else { return 0 }
        var moved = 0
        for saved in windows {
            let matches = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == saved.bundleIdentifier }
            let elements = matches.flatMap { app -> [AXUIElement] in
                let root = AXUIElementCreateApplication(app.processIdentifier)
                var value: CFTypeRef?
                guard AXUIElementCopyAttributeValue(root, kAXWindowsAttribute as CFString, &value) == .success else { return [] }
                return value as? [AXUIElement] ?? []
            }
            guard let target = elements.first(where: { title(of: $0) == saved.title }) ?? elements.first else { continue }
            var point = CGPoint(x: saved.x, y: saved.y)
            var size = CGSize(width: saved.width, height: saved.height)
            guard let position = AXValueCreate(.cgPoint, &point), let dimensions = AXValueCreate(.cgSize, &size) else { continue }
            let p = AXUIElementSetAttributeValue(target, kAXPositionAttribute as CFString, position)
            let s = AXUIElementSetAttributeValue(target, kAXSizeAttribute as CFString, dimensions)
            if p == .success || s == .success { moved += 1 }
        }
        return moved
    }

    private static func title(of window: AXUIElement) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &value) == .success else { return "" }
        return value as? String ?? ""
    }

    private static func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue, let sizeValue else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &point),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: point, size: size)
    }
}
