import AppKit

enum ClickKind: Sendable {
    case leftDown
    case leftUp
    case rightDown
    case rightUp
    case drag

    var isRelease: Bool {
        self == .leftUp || self == .rightUp
    }
}

struct ClickEvent: Sendable {
    let kind: ClickKind
    let location: CGPoint
    let timestamp: TimeInterval
}

final class ClickEventBox: @unchecked Sendable {
    let event: ClickEvent

    init(_ event: ClickEvent) {
        self.event = event
    }
}
