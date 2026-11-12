import AppKit
import ApplicationServices
import Observation

@MainActor
@Observable
final class WindowControls {
    private(set) var hasAccessibility = AXIsProcessTrusted()
    private(set) var targetName = "Select a window in another app"
    private(set) var hasTarget = false
    private(set) var status = ""
    private var target: AXUIElement?
    private var lastApplication: NSRunningApplication?
    private var activationObserver: NSObjectProtocol?
    private var history: [(window: AXUIElement, frame: CGRect)] = []

    init() {
        rememberActiveApplication()
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rememberActiveApplication() }
        }
    }

    func refreshPermission() {
        hasAccessibility = AXIsProcessTrusted()
        if !hasAccessibility {
            target = nil
            hasTarget = false
        }
    }

    func selectFrontmostWindow() {
        refreshPermission()
        rememberActiveApplication()
        guard hasAccessibility, let app = lastApplication, !app.isTerminated else {
            target = nil
            hasTarget = false
            return
        }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 0.2)
        guard let window = Self.element(root, attribute: kAXFocusedWindowAttribute)
                ?? Self.element(root, attribute: kAXMainWindowAttribute) else {
            target = nil
            hasTarget = false
            targetName = "No available window"
            return
        }
        select(window: window, appName: app.localizedName ?? "Window")
    }

    func select(window: AXUIElement, appName: String) {
        target = window
        hasTarget = true
        targetName = appName
        status = ""
        AXUIElementSetMessagingTimeout(window, 0.2)
    }

    func perform(_ action: WindowAction) {
        refreshPermission()
        guard hasAccessibility else {
            status = "Enable Accessibility access in System Settings."
            return
        }
        guard let window = target, let current = Self.frame(of: window) else {
            hasTarget = false
            status = "The selected window is no longer available."
            return
        }
        if action == .fullScreen {
            guard let button = Self.element(window, attribute: kAXFullScreenButtonAttribute),
                  AXUIElementPerformAction(button, kAXPressAction as CFString) == .success else {
                status = "This window does not support full screen."
                return
            }
            status = "Toggled full screen."
            return
        }

        let next: CGRect
        if action == .revert {
            guard let saved = history.first(where: { CFEqual($0.window, window) }) else {
                status = "No previous position for this window."
                return
            }
            next = saved.frame
        } else {
            let screens = NSScreen.screens
            guard let primary = screens.first else { return }
            let bounds = screens.map { WindowGeometry.flip($0.visibleFrame, primaryScreenHeight: primary.frame.height) }
            guard let index = bounds.indices.max(by: {
                Self.intersectionArea(current, bounds[$0]) < Self.intersectionArea(current, bounds[$1])
            }) else { return }
            if action == .previousDisplay || action == .nextDisplay {
                guard bounds.count > 1 else {
                    status = "Connect another display to move this window."
                    return
                }
                let offset = action == .nextDisplay ? 1 : bounds.count - 1
                next = WindowGeometry.transferred(current, from: bounds[index], to: bounds[(index + offset) % bounds.count])
            } else {
                guard let placed = WindowGeometry.placed(action, current: current, bounds: bounds[index]) else { return }
                next = placed
            }
        }
        // Remember even partial changes, so an app's size constraints can be undone.
        history.removeAll { CFEqual($0.window, window) }
        history.append((window: window, frame: current))
        if history.count > 30 { history.removeFirst() }
        Self.setFrame(next, on: window)
        guard let actual = Self.frame(of: window) else {
            status = "Could not read the resulting window position."
            return
        }
        let matches = abs(actual.minX - next.minX) < 3 && abs(actual.minY - next.minY) < 3
            && abs(actual.width - next.width) < 3 && abs(actual.height - next.height) < 3
        status = matches ? action.title : "This app limited the requested window size or position."
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    static func element(_ parent: AXUIElement, attribute name: String) -> AXUIElement? {
        guard let value = attribute(parent, name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    static func frame(of element: AXUIElement) -> CGRect? {
        guard let position = attribute(element, kAXPositionAttribute), CFGetTypeID(position) == AXValueGetTypeID(),
              let size = attribute(element, kAXSizeAttribute), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        let positionValue = position as! AXValue
        let sizeValue = size as! AXValue
        guard AXValueGetType(positionValue) == .cgPoint, AXValueGetType(sizeValue) == .cgSize else { return nil }
        var point = CGPoint.zero
        var dimensions = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &point), AXValueGetValue(sizeValue, .cgSize, &dimensions) else { return nil }
        return CGRect(origin: point, size: dimensions)
    }

    private func rememberActiveApplication() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              app.activationPolicy == .regular else { return }
        lastApplication = app
    }

    private static func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let overlap = lhs.intersection(rhs)
        return overlap.isNull ? 0 : overlap.width * overlap.height
    }

    private static func setFrame(_ frame: CGRect, on window: AXUIElement) {
        var point = frame.origin
        var size = frame.size
        guard let position = AXValueCreate(.cgPoint, &point), let dimensions = AXValueCreate(.cgSize, &size) else { return }
        // Set size again after moving: some apps constrain size to their current display.
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, dimensions)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, dimensions)
    }
}
