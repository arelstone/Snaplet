import Foundation
import Testing
@testable import Snaplet

@MainActor
struct PresetStoreTests {
    private let oldWindow = SavedWindow(bundleIdentifier: "test.editor", title: "Editor", x: 10, y: 20, width: 600, height: 400)
    private let newWindows = [
        SavedWindow(bundleIdentifier: "test.editor", title: "Editor", x: 0, y: 30, width: 900, height: 800),
        SavedWindow(bundleIdentifier: "test.simulator", title: "Simulator", x: 900, y: 30, width: 400, height: 800)
    ]

    @Test func updateKeepsIdentityAndOtherPresetsAndSurvivesReload() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = WindowLayout(name: "Development", savedAt: Date(timeIntervalSince1970: 100), windows: [oldWindow])
        let other = WindowLayout(name: "Laptop", windows: [oldWindow])
        try write([original, other], to: directory)
        let store = PresetStore(directory: directory, captureWindows: { newWindows })

        store.update(original)

        let updated = try #require(store.layouts.first)
        #expect(store.layouts.count == 2)
        #expect(updated.id == original.id)
        #expect(updated.name == original.name)
        #expect(updated.savedAt > original.savedAt)
        #expect(updated.windows == newWindows)
        #expect(store.layouts[1] == other)
        let reloaded = PresetStore(directory: directory, captureWindows: { [] })
        #expect(reloaded.layouts == store.layouts)
    }

    @Test func emptyCapturePreservesExistingPresetAndFile() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = WindowLayout(name: "Development", windows: [oldWindow])
        try write([original], to: directory)
        let file = directory.appendingPathComponent("layouts.json")
        let before = try Data(contentsOf: file)
        let store = PresetStore(directory: directory, captureWindows: { [] })

        store.update(original)

        #expect(store.layouts == [original])
        #expect(try Data(contentsOf: file) == before)
        #expect(store.status.contains("Your saved preset was kept"))
    }

    @Test func missingPresetDoesNotReplaceAnExistingOne() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = WindowLayout(name: "Laptop", windows: [oldWindow])
        try write([original], to: directory)
        let store = PresetStore(directory: directory, captureWindows: { newWindows })

        store.update(WindowLayout(name: "Deleted preset", windows: []))

        #expect(store.layouts == [original])
        #expect(store.status == "This preset no longer exists.")
        #expect(PresetStore(directory: directory, captureWindows: { [] }).layouts == [original])
    }

    @Test func failedWriteRollsBackTheUpdate() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = WindowLayout(name: "Development", windows: [oldWindow])
        try write([original], to: directory)
        let store = PresetStore(directory: directory, captureWindows: { newWindows })
        // Simulate the storage location becoming unavailable after the preset was loaded.
        try FileManager.default.removeItem(at: directory)

        store.update(original)

        #expect(store.layouts == [original])
        #expect(store.status.contains("Could not update"))
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("SnapletTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func write(_ layouts: [WindowLayout], to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(layouts).write(to: directory.appendingPathComponent("layouts.json"), options: .atomic)
    }
}
