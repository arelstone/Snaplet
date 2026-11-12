import AppKit
import ApplicationServices
import SwiftUI

@MainActor
final class PaletteHoverController {
    private let controls: WindowControls
    private let systemWide = AXUIElementCreateSystemWide()
    private var timer: Timer?
    private var candidate: AXUIElement?
    private var candidateSince: TimeInterval = 0
    private var anchor = CGRect.zero
    private var panel: NSPanel?
    private var previousMouse: CGPoint?

    init(controls: WindowControls) {
        self.controls = controls
        AXUIElementSetMessagingTimeout(systemWide, 0.15)
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        dismiss()
    }

    private func update() {
        controls.refreshPermission()
        let enabled = UserDefaults.standard.object(forKey: "paletteHoverEnabled") as? Bool ?? true
        guard enabled, controls.hasAccessibility else {
            dismiss()
            return
        }
        guard let primary = NSScreen.screens.first else { return }
        let mouse = NSEvent.mouseLocation
        if let panel, panel.isVisible {
            // Include the short path between the traffic-light button and palette.
            let bridge = anchor.union(panel.frame)
            if panel.frame.insetBy(dx: -6, dy: -6).contains(mouse)
                || anchor.insetBy(dx: -8, dy: -8).contains(mouse) || bridge.contains(mouse) { return }
            dismiss()
        }
        guard NSEvent.pressedMouseButtons == 0 else {
            candidate = nil
            return
        }
        // Do not repeatedly query another app while the pointer is stationary away from a button.
        if previousMouse == mouse, candidate == nil { return }
        previousMouse = mouse
        var hovered: AXUIElement?
        guard AXUIElementCopyElementAtPosition(systemWide, Float(mouse.x), Float(primary.frame.height - mouse.y), &hovered) == .success,
              let hovered, isZoomButton(hovered),
              let window = WindowControls.element(hovered, attribute: kAXWindowAttribute)
                ?? WindowControls.element(hovered, attribute: kAXParentAttribute),
              WindowControls.attribute(window, kAXRoleAttribute) as? String == kAXWindowRole,
              let buttonFrame = WindowControls.frame(of: hovered) else {
            candidate = nil
            return
        }
        var pid: pid_t = 0
        guard AXUIElementGetPid(window, &pid) == .success,
              pid != ProcessInfo.processInfo.processIdentifier else { return }
        if let candidate, CFEqual(candidate, hovered) {
            let delay = UserDefaults.standard.object(forKey: "paletteHoverDelay") as? Double ?? 0.45
            if ProcessInfo.processInfo.systemUptime - candidateSince >= max(0.15, min(delay, 2)) {
                controls.select(window: window, appName: NSRunningApplication(processIdentifier: pid)?.localizedName ?? "Window")
                anchor = WindowGeometry.flip(buttonFrame, primaryScreenHeight: primary.frame.height)
                show(near: anchor)
            }
        } else {
            candidate = hovered
            candidateSince = ProcessInfo.processInfo.systemUptime
        }
    }

    private func isZoomButton(_ element: AXUIElement) -> Bool {
        if WindowControls.attribute(element, kAXSubroleAttribute) as? String == kAXZoomButtonSubrole { return true }
        guard let window = WindowControls.element(element, attribute: kAXWindowAttribute),
              let zoom = WindowControls.element(window, attribute: kAXZoomButtonAttribute) else { return false }
        return CFEqual(element, zoom)
    }

    private func show(near button: CGRect) {
        if panel == nil {
            let created = NSPanel(contentRect: CGRect(x: 0, y: 0, width: 280, height: 200),
                                  styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            created.level = .popUpMenu
            created.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            created.isOpaque = false
            created.backgroundColor = .clear
            created.hasShadow = true
            created.hidesOnDeactivate = false
            created.becomesKeyOnlyIfNeeded = true
            created.isReleasedWhenClosed = false
            created.contentView = NSHostingView(rootView: HoverPalette(controls: controls))
            panel = created
        }
        guard let panel,
              let screen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: button.midX, y: button.midY)) }) else { return }
        let bounds = screen.visibleFrame
        let x = max(bounds.minX + 6, min(button.minX - 12, bounds.maxX - panel.frame.width - 6))
        var y = button.minY - panel.frame.height - 8
        if y < bounds.minY { y = min(button.maxY + 8, bounds.maxY - panel.frame.height) }
        panel.setFrameOrigin(CGPoint(x: x, y: y))
        panel.orderFrontRegardless()
    }

    private func dismiss() {
        panel?.orderOut(nil)
        candidate = nil
    }
}
