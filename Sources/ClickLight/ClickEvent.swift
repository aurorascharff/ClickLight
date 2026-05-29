import AppKit

enum ClickKind: Sendable {
    case leftDown
    case leftUp
    case rightDown
    case rightUp
    case middleDown
    case middleUp
    case drag
    case move

    var isRelease: Bool {
        self == .leftUp || self == .rightUp || self == .middleUp
    }
}

struct ClickEvent: Sendable {
    let kind: ClickKind
    let location: CGPoint
    let timestamp: TimeInterval
}

struct KeyboardShortcutEvent: Sendable {
    let displayString: String
    let location: CGPoint
    let timestamp: TimeInterval
}

final class ClickEventBox: @unchecked Sendable {
    let event: ClickEvent

    init(_ event: ClickEvent) {
        self.event = event
    }
}

final class KeyboardShortcutEventBox: @unchecked Sendable {
    let event: KeyboardShortcutEvent

    init(_ event: KeyboardShortcutEvent) {
        self.event = event
    }
}
