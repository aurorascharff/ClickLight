import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let hotKeyRegistrationIssuesDidChangeNotification = Notification.Name("ClickLightHotKeyRegistrationIssuesDidChange")

    private let settingsStore = SettingsStore()
    private var settingsWindowController: SettingsWindowController?
    private let hotKeyManager = HotKeyManager()
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
    private var hotKeyBindingsState: [ClickShortcutAction: HotKeyBinding] = [:]
    private var hotKeyRegistrationIssuesState: [ClickShortcutAction: String] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        overlayCoordinator.start()
        permissions.requestAccessibilityIfNeeded()
        captureEnabledState = settingsStore.settings.isEnabled
        laserPointerEnabledState = settingsStore.settings.showLaserPointer
        captureController.startIfEnabled()
        statusController.start()
        configureHotKeysIfNeeded(with: settingsStore.settings, force: true)

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
        hotKeyManager.unregisterAll()
    }

    @objc private func settingsDidChange() {
        let settings = settingsStore.settings
        overlayCoordinator.refreshSettings()
        configureHotKeysIfNeeded(with: settings)
        let isEnabled = settings.isEnabled
        let laserPointerEnabled = settings.showLaserPointer
        guard captureEnabledState != isEnabled || laserPointerEnabledState != laserPointerEnabled else { return }
        captureEnabledState = isEnabled
        laserPointerEnabledState = laserPointerEnabled
        captureController.refreshEnabledState()
    }

    private func configureHotKeysIfNeeded(with settings: ClickSettings, force: Bool = false) {
        let bindings = settings.shortcutBindings
        guard force || bindings != hotKeyBindingsState else { return }

        hotKeyBindingsState = bindings
        let issues = hotKeyManager.registerShortcuts(bindings) { [weak self] action in
            self?.handleHotKeyAction(action)
        }
        publishHotKeyRegistrationIssuesIfNeeded(issues)
    }

    private func publishHotKeyRegistrationIssuesIfNeeded(_ issues: [ClickShortcutAction: String]) {
        guard issues != hotKeyRegistrationIssuesState else { return }

        hotKeyRegistrationIssuesState = issues
        let serializedIssues = Dictionary(uniqueKeysWithValues: issues.map { ($0.key.rawValue, $0.value) })
        NotificationCenter.default.post(
            name: Self.hotKeyRegistrationIssuesDidChangeNotification,
            object: self,
            userInfo: ["issues": serializedIssues]
        )
    }

    private func handleHotKeyAction(_ action: ClickShortcutAction) {
        switch action {
        case .toggleEnabled:
            settingsStore.update { $0.isEnabled.toggle() }
        case .toggleLaserPointer:
            settingsStore.update { $0.showLaserPointer.toggle() }
        case .toggleShowPress:
            settingsStore.update { $0.showPress.toggle() }
        case .toggleShowRelease:
            settingsStore.update { $0.showRelease.toggle() }
        case .toggleShowRightClick:
            settingsStore.update { $0.showRightClick.toggle() }
        case .toggleShowMiddleClick:
            settingsStore.update { $0.showMiddleClick.toggle() }
        case .toggleShowDrag:
            settingsStore.update { $0.showDrag.toggle() }
        }
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
            hotKeyRegistrationIssuesProvider: { [weak self] in
                self?.hotKeyRegistrationIssuesState ?? [:]
            },
            onTestPulse: { [weak self] in self?.showTestPulse() }
        )
        settingsWindowController = controller
        controller.show()
    }
}
