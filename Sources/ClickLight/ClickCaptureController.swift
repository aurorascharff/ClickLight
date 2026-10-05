import Foundation

protocol ClickEventCapturing: AnyObject {
    var statusLabel: String { get }
    var usesEventTap: Bool { get }

    func start(
        laserPointerEnabled: Bool,
        liveKeyboardShortcutsEnabled: Bool,
        releaseSuppressionShortcutEnabled: Bool
    )
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

    var usesEventTap: Bool {
        eventTap.usesEventTap
    }

    func startIfEnabled() {
        guard settingsStore.settings.isEnabled else { return }
        eventTap.start(
            laserPointerEnabled: settingsStore.settings.showLaserPointer,
            liveKeyboardShortcutsEnabled: settingsStore.settings.showLiveKeyboardShortcuts,
            releaseSuppressionShortcutEnabled: settingsStore.settings.listensForReleaseSuppressionShortcut
        )
    }

    func refreshEnabledState() {
        if settingsStore.settings.isEnabled {
            eventTap.start(
                laserPointerEnabled: settingsStore.settings.showLaserPointer,
                liveKeyboardShortcutsEnabled: settingsStore.settings.showLiveKeyboardShortcuts,
                releaseSuppressionShortcutEnabled: settingsStore.settings.listensForReleaseSuppressionShortcut
            )
        } else {
            eventTap.stop()
        }
    }

    func stop() {
        eventTap.stop()
    }
}
