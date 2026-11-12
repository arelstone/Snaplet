import Foundation

enum WindowAction: String, CaseIterable, Identifiable {
    case fill, leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight, center
    case previousDisplay, nextDisplay, fullScreen, revert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fill: "Fill Screen"
        case .leftHalf: "Left Half"
        case .rightHalf: "Right Half"
        case .topHalf: "Top Half"
        case .bottomHalf: "Bottom Half"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .center: "Center"
        case .previousDisplay: "Previous Display"
        case .nextDisplay: "Next Display"
        case .fullScreen: "Toggle Full Screen"
        case .revert: "Revert"
        }
    }

    /// A top-left-origin unit rectangle, also used to draw palette icons.
    var region: CGRect? {
        switch self {
        case .fill: CGRect(x: 0, y: 0, width: 1, height: 1)
        case .leftHalf: CGRect(x: 0, y: 0, width: 0.5, height: 1)
        case .rightHalf: CGRect(x: 0.5, y: 0, width: 0.5, height: 1)
        case .topHalf: CGRect(x: 0, y: 0, width: 1, height: 0.5)
        case .bottomHalf: CGRect(x: 0, y: 0.5, width: 1, height: 0.5)
        case .topLeft: CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        case .topRight: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)
        case .bottomLeft: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
        case .bottomRight: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        default: nil
        }
    }
}

enum WindowGeometry {
    /// AX uses a top-left origin; AppKit uses a bottom-left origin.
    static func flip(_ rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryScreenHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    static func placed(_ action: WindowAction, current: CGRect, bounds: CGRect) -> CGRect? {
        if let region = action.region {
            return CGRect(x: bounds.minX + bounds.width * region.minX,
                          y: bounds.minY + bounds.height * region.minY,
                          width: bounds.width * region.width, height: bounds.height * region.height)
        }
        guard action == .center else { return nil }
        let size = CGSize(width: min(current.width, bounds.width), height: min(current.height, bounds.height))
        return CGRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2,
                      width: size.width, height: size.height)
    }

    static func transferred(_ current: CGRect, from source: CGRect, to destination: CGRect) -> CGRect {
        let size = CGSize(width: min(current.width, destination.width), height: min(current.height, destination.height))
        let xFraction = source.width > current.width ? (current.minX - source.minX) / (source.width - current.width) : 0
        let yFraction = source.height > current.height ? (current.minY - source.minY) / (source.height - current.height) : 0
        return CGRect(x: destination.minX + max(0, min(1, xFraction)) * (destination.width - size.width),
                      y: destination.minY + max(0, min(1, yFraction)) * (destination.height - size.height),
                      width: size.width, height: size.height)
    }
}
