import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private var settingsWindowController: SettingsWindowController?
    private lazy var overlayCoordinator = OverlayCoordinator(settingsStore: settingsStore)
    private lazy var captureController = ClickCaptureController(settingsStore: settingsStore, eventTap: eventTap)
    private lazy var statusController = StatusController(
        settingsStore: settingsStore,
        permissions: permissions,
        launchAtLogin: launchAtLogin,
        captureStatus: { [weak self] in self?.captureController.statusLabel ?? "Not Started" },
        onCheckForUpdates: { UpdateChecker.shared.checkForUpdates() },
        updatesAreConfigured: { UpdateChecker.shared.isConfigured },
        onOpenSettings: { [weak self] in self?.openSettings() },
        onTestPulse: { [weak self] in self?.showTestPulse() },
        onQuit: { NSApplication.shared.terminate(nil) }
    )
    private let eventTap = ClickEventTap()
    private let permissions = PermissionController()
    private let launchAtLogin = LaunchAtLoginController()
    private var captureEnabledState: Bool?
    private var laserPointerEnabledState: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        overlayCoordinator.start()
        permissions.requestAccessibilityIfNeeded()
        captureEnabledState = settingsStore.settings.isEnabled
        laserPointerEnabledState = settingsStore.settings.showLaserPointer
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
        let settings = settingsStore.settings
        let isEnabled = settings.isEnabled
        let laserPointerEnabled = settings.showLaserPointer
        guard captureEnabledState != isEnabled || laserPointerEnabledState != laserPointerEnabled else { return }
        captureEnabledState = isEnabled
        laserPointerEnabledState = laserPointerEnabled
        captureController.refreshEnabledState()
    }

    @objc private func clickEventDidArrive(_ notification: Notification) {
        guard let box = notification.object as? ClickEventBox else { return }
        guard settingsWindowController?.contains(box.event.location) != true else { return }
        overlayCoordinator.show(box.event)
    }

    private func showTestPulse() {
        overlayCoordinator.show(ClickEvent(
            kind: .leftDown,
            location: NSEvent.mouseLocation,
            timestamp: CACurrentMediaTime()
        ))
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "ClickLight")

        let quitItem = NSMenuItem(
            title: "Quit ClickLight",
            action: #selector(handleQuitShortcut),
            keyEquivalent: "q"
        )
        quitItem.target = self
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc private func handleQuitShortcut() {
        NSApp.terminate(nil)
    }

    private func openSettings() {
        let controller = settingsWindowController ?? SettingsWindowController(
            settingsStore: settingsStore,
            launchAtLogin: launchAtLogin,
            permissions: permissions,
            onTestPulse: { [weak self] in self?.showTestPulse() }
        )
        settingsWindowController = controller
        controller.show()
    }
}
