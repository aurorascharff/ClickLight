import Foundation

protocol ClickEventCapturing: AnyObject {
    var statusLabel: String { get }

    func start(laserPointerEnabled: Bool)
    func stop()
}

@MainActor
final class ClickCaptureController {
    private let settingsStore: SettingsStore
    private let eventTap: ClickEventCapturing

    init(settingsStore: SettingsStore, eventTap: ClickEventCapturing) {
        self.settingsStore = settingsStore
        self.eventTap = eventTap
    }

    var statusLabel: String {
        eventTap.statusLabel
    }

    func startIfEnabled() {
        guard settingsStore.settings.isEnabled else { return }
        eventTap.start(laserPointerEnabled: settingsStore.settings.showLaserPointer)
    }

    func refreshEnabledState() {
        if settingsStore.settings.isEnabled {
            eventTap.start(laserPointerEnabled: settingsStore.settings.showLaserPointer)
        } else {
            eventTap.stop()
        }
    }

    func stop() {
        eventTap.stop()
    }
}
