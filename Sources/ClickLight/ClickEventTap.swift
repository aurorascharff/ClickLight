import AppKit

final class ClickEventTap: ClickEventCapturing {
    static let didReceiveClickEvent = Notification.Name("ClickLightDidReceiveClickEvent")

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?
    private var laserPointerEnabled = false

    var statusLabel: String {
        switch (eventTap != nil, globalMonitor != nil) {
        case (true, true):
            return "Event Tap + Fallback"
        case (true, false):
            return "Event Tap"
        case (false, true):
            return "Fallback"
        case (false, false):
            return "Stopped"
        }
    }

    func start(laserPointerEnabled: Bool) {
        if self.laserPointerEnabled != laserPointerEnabled {
            stop()
            self.laserPointerEnabled = laserPointerEnabled
        }
        startEventTapIfNeeded()
        startGlobalMonitorIfNeeded()
    }

    func stop() {
        stopEventTap()
        stopGlobalMonitor()
    }

    private func startEventTapIfNeeded() {
        guard eventTap == nil else { return }

        var types = [
            CGEventType.leftMouseDown,
            CGEventType.leftMouseUp,
            CGEventType.rightMouseDown,
            CGEventType.rightMouseUp,
            CGEventType.otherMouseDown,
            CGEventType.otherMouseUp,
            CGEventType.leftMouseDragged,
            CGEventType.rightMouseDragged,
            CGEventType.otherMouseDragged
        ]
        if laserPointerEnabled {
            types.append(.mouseMoved)
        }
        let mask = types.reduce(CGEventMask(0)) { partial, eventType in
            partial | (1 << CGEventMask(eventType.rawValue))
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: userInfo
        ) else {
            return
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func stopEventTap() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private func startGlobalMonitorIfNeeded() {
        guard globalMonitor == nil else { return }

        var eventTypes: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .otherMouseDown,
            .otherMouseUp,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged
        ]
        if laserPointerEnabled {
            eventTypes.insert(.mouseMoved)
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventTypes) { event in
            guard let kind = ClickKind(event: event) else { return }
            Self.post(kind: kind, timestamp: event.timestamp)
        }
    }

    private func stopGlobalMonitor() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        globalMonitor = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard let kind = ClickKind(type: type, event: event) else {
            return Unmanaged.passUnretained(event)
        }

        Self.post(kind: kind, timestamp: event.timestampSeconds)

        return Unmanaged.passUnretained(event)
    }

    private static func post(kind: ClickKind, timestamp: TimeInterval) {
        DispatchQueue.main.async {
            let clickEvent = ClickEvent(
                kind: kind,
                location: NSEvent.mouseLocation,
                timestamp: timestamp
            )
            NotificationCenter.default.post(name: Self.didReceiveClickEvent, object: ClickEventBox(clickEvent))
        }
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else {
        return Unmanaged.passUnretained(event)
    }

    let listener = Unmanaged<ClickEventTap>.fromOpaque(refcon).takeUnretainedValue()
    return listener.handle(type: type, event: event)
}

private extension ClickKind {
    init?(type: CGEventType, event: CGEvent) {
        switch type {
        case .leftMouseDown:
            self = .leftDown
        case .leftMouseUp:
            self = .leftUp
        case .rightMouseDown:
            self = .rightDown
        case .rightMouseUp:
            self = .rightUp
        case .otherMouseDown where event.buttonNumber == 2:
            self = .middleDown
        case .otherMouseUp where event.buttonNumber == 2:
            self = .middleUp
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            self = .drag
        case .mouseMoved:
            self = .move
        default:
            return nil
        }
    }

    init?(event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            self = .leftDown
        case .leftMouseUp:
            self = .leftUp
        case .rightMouseDown:
            self = .rightDown
        case .rightMouseUp:
            self = .rightUp
        case .otherMouseDown where event.buttonNumber == 2:
            self = .middleDown
        case .otherMouseUp where event.buttonNumber == 2:
            self = .middleUp
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            self = .drag
        case .mouseMoved:
            self = .move
        default:
            return nil
        }
    }
}

private extension CGEvent {
    var buttonNumber: Int64 {
        getIntegerValueField(.mouseEventButtonNumber)
    }

    var timestampSeconds: TimeInterval {
        TimeInterval(timestamp) / 1_000_000_000
    }
}
