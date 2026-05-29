import AppKit

@MainActor
final class OverlayCoordinator {
    private let settingsStore: SettingsStore
    private var settings: ClickSettings
    private var overlaysByScreenID: [NSNumber: ClickOverlayWindow] = [:]
    private var recentEvents: [ClickEvent] = []
    private var recentShortcutEvents: [KeyboardShortcutEvent] = []

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.settings = settingsStore.settings
    }

    func start() {
        rebuildOverlays()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func refreshSettings() {
        settings = settingsStore.settings
        overlaysByScreenID.values.forEach { $0.apply(settings: settings) }
    }

    func show(_ event: ClickEvent) {
        guard settings.isEnabled else { return }
        guard settings.showLaserPointer || shouldShow(event.kind) else { return }
        guard shouldAccept(event) else { return }
        guard let screen = screen(containing: event.location) else { return }

        let screenID = screen.identifier
        if overlaysByScreenID[screenID] == nil {
            rebuildOverlays()
        }

        overlaysByScreenID[screenID]?.show(event: event, settings: settings)
    }

    func show(_ event: KeyboardShortcutEvent) {
        guard settings.isEnabled, settings.showLiveKeyboardShortcuts else { return }
        guard shouldAccept(event) else { return }
        guard let screen = screen(containing: event.location) else { return }

        let screenID = screen.identifier
        if overlaysByScreenID[screenID] == nil {
            rebuildOverlays()
        }

        overlaysByScreenID[screenID]?.show(shortcut: event, settings: settings)
    }

    @objc private func screenParametersDidChange() {
        rebuildOverlays()
    }

    private func rebuildOverlays() {
        overlaysByScreenID.values.forEach { $0.close() }
        overlaysByScreenID = Dictionary(
            uniqueKeysWithValues: NSScreen.screens.map { screen in
                let window = ClickOverlayWindow(screen: screen, settings: settings)
                window.orderFrontRegardless()
                return (screen.identifier, window)
            }
        )
    }

    private func shouldShow(_ kind: ClickKind) -> Bool {
        switch kind {
        case .leftDown:
            return settings.showPress
        case .leftUp:
            return settings.showRelease
        case .rightDown, .rightUp:
            return settings.showRightClick
        case .middleDown, .middleUp:
            return settings.showMiddleClick
        case .drag:
            return settings.showDrag
        case .move:
            return false
        }
    }

    private func shouldAccept(_ event: ClickEvent) -> Bool {
        let now = CACurrentMediaTime()
        recentEvents = recentEvents.filter { now - $0.timestamp < 0.1 }
        let duplicate = recentEvents.contains { existing in
            existing.kind == event.kind &&
            abs(existing.location.x - event.location.x) < 3 &&
            abs(existing.location.y - event.location.y) < 3
        }
        if !duplicate {
            recentEvents.append(event)
        }
        return !duplicate
    }

    private func shouldAccept(_ event: KeyboardShortcutEvent) -> Bool {
        let now = CACurrentMediaTime()
        recentShortcutEvents = recentShortcutEvents.filter { now - $0.timestamp < 0.1 }
        let duplicate = recentShortcutEvents.contains { existing in
            existing.displayString == event.displayString
        }
        if !duplicate {
            recentShortcutEvents.append(event)
        }
        return !duplicate
    }

    private func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
    }
}

private extension NSScreen {
    var identifier: NSNumber {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as? NSNumber ?? NSNumber(value: frame.hashValue)
    }
}
