import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = PresetStore()
    let controls = WindowControls()
    private var hover: PaletteHoverController?
    private var manager: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hover = PaletteHoverController(controls: controls)
        self.hover = hover
        hover.start()
        if !controls.hasAccessibility { showManager() }
    }

    func showManager() {
        if manager == nil {
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 580, height: 560),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Snaplet"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: ContentView(store: store, controls: controls))
            window.center()
            manager = window
        }
        manager?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showManager()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        hover?.stop()
    }
}

@main
struct SnapletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Snaplet", systemImage: "rectangle.3.group") {
            MenuPalette(store: delegate.store, controls: delegate.controls, showManager: delegate.showManager)
        }
        .menuBarExtraStyle(.window)

    }
}
