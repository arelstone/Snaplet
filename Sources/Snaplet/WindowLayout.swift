import Foundation

struct WindowLayout: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var savedAt: Date = .now
    var windows: [SavedWindow]
}

struct SavedWindow: Codable, Equatable {
    var bundleIdentifier: String
    var title: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
