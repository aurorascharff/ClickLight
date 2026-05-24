import AppKit

enum CoordinateMapper {
    static func appKitPoint(from quartzPoint: CGPoint) -> CGPoint {
        let screens = NSScreen.screens
        if screens.contains(where: { $0.frame.contains(quartzPoint) }) {
            return quartzPoint
        }

        if let flipped = pointFlippedFromMainDisplay(quartzPoint), screens.contains(where: { $0.frame.contains(flipped) }) {
            return flipped
        }

        return NSEvent.mouseLocation
    }

    private static func pointFlippedFromMainDisplay(_ point: CGPoint) -> CGPoint? {
        guard let mainScreen = NSScreen.main else { return nil }
        return CGPoint(x: point.x, y: mainScreen.frame.maxY - point.y)
    }
}
