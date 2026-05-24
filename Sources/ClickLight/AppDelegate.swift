import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private lazy var overlayCoordinator = OverlayCoordinator(settingsStore: settingsStore)
    private lazy var captureController = ClickCaptureController(settingsStore: settingsStore, eventTap: eventTap)
    private lazy var statusController = StatusController(
        settingsStore: settingsStore,
        permissions: permissions,
        captureStatus: { [weak self] in self?.captureController.statusLabel ?? "Not Started" },
        onCheckForUpdates: { UpdateChecker.shared.checkForUpdates() },
        updatesAreConfigured: { UpdateChecker.shared.isConfigured },
        onTestPulse: { [weak self] in self?.showTestPulse() },
        onQuit: { NSApplication.shared.terminate(nil) }
    )
    private let eventTap = ClickEventTap()
    private let permissions = PermissionController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlayCoordinator.start()
        permissions.requestAccessibilityIfNeeded()
        captureController.startIfEnabled()
        statusController.start()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: SettingsStore.didChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clickEventDidArrive(_:)),
            name: ClickEventTap.didReceiveClickEvent,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        captureController.stop()
    }

    @objc private func settingsDidChange() {
        overlayCoordinator.refreshSettings()
        captureController.refreshEnabledState()
    }

    @objc private func clickEventDidArrive(_ notification: Notification) {
        guard let box = notification.object as? ClickEventBox else { return }
        overlayCoordinator.show(box.event)
    }

    private func showTestPulse() {
        overlayCoordinator.show(ClickEvent(
            kind: .leftDown,
            location: NSEvent.mouseLocation,
            timestamp: CACurrentMediaTime()
        ))
    }
}
