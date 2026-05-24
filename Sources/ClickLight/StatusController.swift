import AppKit

@MainActor
final class StatusController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settingsStore: SettingsStore
    private let permissions: PermissionController
    private let captureStatus: () -> String
    private let onTestPulse: () -> Void
    private let onQuit: () -> Void

    init(
        settingsStore: SettingsStore,
        permissions: PermissionController,
        captureStatus: @escaping () -> String,
        onTestPulse: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.permissions = permissions
        self.captureStatus = captureStatus
        self.onTestPulse = onTestPulse
        self.onQuit = onQuit
    }

    func start() {
        statusItem.button?.image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: "ClickLight")
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = "ClickLight"
        rebuildMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: SettingsStore.didChangeNotification,
            object: nil
        )
    }

    @objc private func settingsDidChange() {
        rebuildMenu()
    }

    private func rebuildMenu() {
        let settings = settingsStore.settings
        let menu = NSMenu()

        menu.addItem(toggleItem(
            title: "Enabled",
            isOn: settings.isEnabled,
            action: #selector(toggleEnabled)
        ))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(toggleItem(
            title: "Show Press",
            isOn: settings.showPress,
            action: #selector(togglePress)
        ))
        menu.addItem(toggleItem(
            title: "Show Release",
            isOn: settings.showRelease,
            action: #selector(toggleRelease)
        ))
        menu.addItem(toggleItem(
            title: "Show Right Click",
            isOn: settings.showRightClick,
            action: #selector(toggleRightClick)
        ))
        menu.addItem(toggleItem(
            title: "Show Drag",
            isOn: settings.showDrag,
            action: #selector(toggleDrag)
        ))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(submenu(
            title: "Size",
            options: [
                ("Small", 44),
                ("Medium", 64),
                ("Large", 88),
                ("Huge", 116)
            ],
            selected: settings.size,
            action: #selector(selectSize(_:))
        ))
        menu.addItem(submenu(
            title: "Intensity",
            options: [
                ("Subtle", 0.28),
                ("Normal", 0.7),
                ("Bright", 1.0),
                ("Beacon", 1.35)
            ],
            selected: settings.intensity,
            action: #selector(selectIntensity(_:))
        ))
        menu.addItem(submenu(
            title: "Duration",
            options: [
                ("Snappy", 0.28),
                ("Normal", 0.48),
                ("Slow", 0.72),
                ("Very Slow", 1.0)
            ],
            selected: settings.duration,
            action: #selector(selectDuration(_:))
        ))
        menu.addItem(NSMenuItem.separator())

        let captureItem = NSMenuItem(title: "Click Capture: \(captureStatus())", action: nil, keyEquivalent: "")
        captureItem.isEnabled = false
        menu.addItem(captureItem)

        let testPulseItem = NSMenuItem(title: "Test Pulse at Pointer", action: #selector(testPulse), keyEquivalent: "")
        testPulseItem.target = self
        menu.addItem(testPulseItem)
        menu.addItem(NSMenuItem.separator())

        let permissionTitle = permissions.isAccessibilityTrusted ? "Accessibility: Granted" : "Open Accessibility Settings..."
        let permissionItem = NSMenuItem(title: permissionTitle, action: #selector(openAccessibilitySettings), keyEquivalent: "")
        permissionItem.target = self
        permissionItem.isEnabled = true
        menu.addItem(permissionItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit ClickLight", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func toggleItem(title: String, isOn: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = isOn ? .on : .off
        return item
    }

    private func submenu(
        title: String,
        options: [(String, Double)],
        selected: CGFloat,
        action: Selector
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu()
        for option in options {
            let child = NSMenuItem(title: option.0, action: action, keyEquivalent: "")
            child.target = self
            child.representedObject = option.1
            child.state = abs(Double(selected) - option.1) < 0.01 ? .on : .off
            menu.addItem(child)
        }
        item.submenu = menu
        return item
    }

    @objc private func toggleEnabled() {
        settingsStore.update { $0.isEnabled.toggle() }
    }

    @objc private func togglePress() {
        settingsStore.update { $0.showPress.toggle() }
    }

    @objc private func toggleRelease() {
        settingsStore.update { $0.showRelease.toggle() }
    }

    @objc private func toggleRightClick() {
        settingsStore.update { $0.showRightClick.toggle() }
    }

    @objc private func toggleDrag() {
        settingsStore.update { $0.showDrag.toggle() }
    }

    @objc private func selectSize(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        settingsStore.update { $0.size = CGFloat(value) }
    }

    @objc private func selectIntensity(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        settingsStore.update { $0.intensity = CGFloat(value) }
    }

    @objc private func selectDuration(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        settingsStore.update { $0.duration = value }
    }

    @objc private func openAccessibilitySettings() {
        permissions.requestAccessibilityIfNeeded()
        permissions.openPrivacySettings()
    }

    @objc private func testPulse() {
        onTestPulse()
    }

    @objc private func quit() {
        onQuit()
    }
}
