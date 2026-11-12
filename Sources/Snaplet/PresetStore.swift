import ApplicationServices
import Foundation
import Observation

@Observable
@MainActor
final class PresetStore {
    private(set) var layouts: [WindowLayout] = []
    var status = "Arrange your windows, then save a named layout."
    private let url: URL
    private let captureWindows: @MainActor () -> [SavedWindow]

    init(directory: URL? = nil, captureWindows: @escaping @MainActor () -> [SavedWindow] = { WindowController.capture() }) {
        // Retain the original storage location so existing presets survive the app rename.
        let directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Snaplet", isDirectory: true)
        self.captureWindows = captureWindows
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("layouts.json")
        load()
    }

    func save(name: String) {
        let windows = captureWindows()
        guard !windows.isEmpty else {
            status = "No eligible windows found. Check Accessibility access in System Settings."
            return
        }
        layouts.insert(WindowLayout(name: name, windows: windows), at: 0)
        persist()
        status = "Saved \(windows.count) windows in ‘\(name)’."
    }

    func update(_ layout: WindowLayout) {
        guard let index = layouts.firstIndex(where: { $0.id == layout.id }) else {
            status = "This preset no longer exists."
            return
        }
        let windows = captureWindows()
        guard !windows.isEmpty else {
            status = "No eligible windows found. Your saved preset was kept. Check Accessibility access in System Settings."
            return
        }
        let original = layouts[index]
        layouts[index].windows = windows
        layouts[index].savedAt = .now
        guard persist() else {
            layouts[index] = original
            status = "Could not update ‘\(original.name)’. Your saved preset was kept."
            return
        }
        status = "Updated \(windows.count) windows in ‘\(original.name)’."
    }

    func restore(_ layout: WindowLayout) {
        guard AXIsProcessTrusted() else {
            status = "Enable Accessibility access before restoring a layout."
            return
        }
        let moved = WindowController.restore(layout.windows)
        status = "Restored \(moved) of \(layout.windows.count) windows. Apps must be open."
    }

    func delete(_ layout: WindowLayout) {
        layouts.removeAll { $0.id == layout.id }
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([WindowLayout].self, from: data) else { return }
        layouts = decoded
    }

    @discardableResult
    private func persist() -> Bool {
        do {
            let data = try JSONEncoder().encode(layouts)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
