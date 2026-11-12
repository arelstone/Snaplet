import Foundation
import Testing
@testable import Snaplet

struct WindowGeometryTests {
    @Test func verticallyStackedAndNegativeScreensRoundTrip() {
        let screens = [
            CGRect(x: 0, y: 25, width: 1440, height: 835),
            CGRect(x: -1920, y: -200, width: 1920, height: 1080),
            CGRect(x: 200, y: 900, width: 2560, height: 1440)
        ]
        for screen in screens {
            let ax = WindowGeometry.flip(screen, primaryScreenHeight: 900)
            #expect(WindowGeometry.flip(ax, primaryScreenHeight: 900) == screen)
        }
        #expect(WindowGeometry.flip(screens[0], primaryScreenHeight: 900).minY == 40)
        #expect(WindowGeometry.flip(screens[2], primaryScreenHeight: 900).minY == -1440)
    }

    @Test func quarterTilesCoverVisibleScreenWithoutOverlap() throws {
        let bounds = CGRect(x: -1920, y: 38, width: 1920, height: 1020)
        let current = CGRect(x: 50, y: 100, width: 600, height: 500)
        let quarters = try [WindowAction.topLeft, .topRight, .bottomLeft, .bottomRight].map {
            try #require(WindowGeometry.placed($0, current: current, bounds: bounds))
        }
        #expect(quarters.reduce(CGRect.null) { $0.union($1) } == bounds)
        for i in quarters.indices {
            #expect(bounds.contains(quarters[i]))
            for j in quarters.indices where j > i {
                let overlap = quarters[i].intersection(quarters[j])
                #expect(overlap.isNull || overlap.width * overlap.height == 0)
            }
        }
        #expect(quarters[0].minY == bounds.minY)
        #expect(quarters[3].maxY == bounds.maxY)
    }

    @Test func transferringFromExternalToLaptopClampsOversizedWindow() {
        let external = CGRect(x: -2560, y: -300, width: 2560, height: 1400)
        let laptop = CGRect(x: 0, y: 32, width: 1440, height: 820)
        let oversized = CGRect(x: -2400, y: -100, width: 2200, height: 1200)
        let transferred = WindowGeometry.transferred(oversized, from: external, to: laptop)
        #expect(transferred == laptop)
    }

    @Test func transferPreservesBottomRightAlignmentAcrossDisplays() {
        let source = CGRect(x: -1920, y: 24, width: 1920, height: 1056)
        let destination = CGRect(x: 0, y: 38, width: 1440, height: 822)
        let current = CGRect(x: -600, y: 580, width: 600, height: 500)
        let result = WindowGeometry.transferred(current, from: source, to: destination)
        #expect(result.maxX == destination.maxX)
        #expect(result.maxY == destination.maxY)
        #expect(result.size == current.size)
    }

    @Test func centerKeepsOversizedWindowVisible() throws {
        let bounds = CGRect(x: -100, y: -600, width: 800, height: 500)
        let result = try #require(WindowGeometry.placed(.center, current: CGRect(x: 0, y: 0, width: 1000, height: 800), bounds: bounds))
        #expect(result == bounds)
    }
}
