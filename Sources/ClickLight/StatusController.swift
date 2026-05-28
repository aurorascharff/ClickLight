import AppKit

@MainActor
final class StatusController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settingsStore: SettingsStore
    private let permissions: PermissionController
    private let launchAtLogin: LaunchAtLoginManaging
    private let captureStatus: () -> String
    private let onCheckForUpdates: () -> Void
    private let updatesAreConfigured: () -> Bool
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void
    private var pendingMenuRebuild: DispatchWorkItem?

    init(
        settingsStore: SettingsStore,
        permissions: PermissionController,
        launchAtLogin: LaunchAtLoginManaging,
        captureStatus: @escaping () -> String,
        onCheckForUpdates: @escaping () -> Void,
        updatesAreConfigured: @escaping () -> Bool,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.permissions = permissions
        self.launchAtLogin = launchAtLogin
        self.captureStatus = captureStatus
        self.onCheckForUpdates = onCheckForUpdates
        self.updatesAreConfigured = updatesAreConfigured
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
    }

    func start() {
        statusItem.button?.image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: "ClickLight")
        statusItem.button?.toolTip = "ClickLight"
        applyStatusItemAppearance(settingsStore.settings)
        rebuildMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: SettingsStore.didChangeNotification,
            object: nil
        )
    }

    func refresh() {
        rebuildMenu()
    }

    @objc private func settingsDidChange() {
        applyStatusItemAppearance(settingsStore.settings)
        pendingMenuRebuild?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.rebuildMenu()
        }
        pendingMenuRebuild = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    private func rebuildMenu() {
        let settings = settingsStore.settings
        let menu = NSMenu()
        StatusMenuConfiguration.apply(to: menu)

        menu.addItem(toggleItem(
            title: "Enabled",
            isOn: settings.isEnabled,
            action: #selector(toggleEnabled)
        ))
        let openSettingsItem = NSMenuItem(title: "Open Settings...", action: #selector(openSettings), keyEquivalent: ",")
        openSettingsItem.target = self
        menu.addItem(openSettingsItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(toggleItem(
            title: "Laser Pointer Mode",
            isOn: settings.showLaserPointer,
            action: #selector(toggleLaserPointer)
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
            title: "Show Middle Click",
            isOn: settings.showMiddleClick,
            action: #selector(toggleMiddleClick)
        ))
        let showDragItem = toggleItem(
            title: "Show Drag",
            isOn: settings.showDrag,
            action: #selector(toggleDrag)
        )
        showDragItem.isEnabled = !settings.showLaserPointer
        menu.addItem(showDragItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(toggleItem(
            title: "Show Menu Bar Text",
            isOn: settings.showMenuBarText,
            action: #selector(toggleMenuBarText)
        ))
        menu.addItem(toggleItem(
            title: "Launch at Login",
            isOn: launchAtLogin.isEnabled,
            action: #selector(toggleLaunchAtLogin)
        ))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(submenu(
            title: "Size",
            options: ClickSettingOptions.sizePresets,
            selected: Double(settings.size),
            action: #selector(selectSize(_:))
        ))
        menu.addItem(submenu(
            title: "Intensity",
            options: ClickSettingOptions.intensityPresets,
            selected: Double(settings.intensity),
            action: #selector(selectIntensity(_:))
        ))
        menu.addItem(submenu(
            title: "Duration",
            options: ClickSettingOptions.durationPresets,
            selected: settings.duration,
            action: #selector(selectDuration(_:))
        ))
        menu.addItem(colorSubmenu(selected: settings.colorPreset))
        menu.addItem(NSMenuItem.separator())

        let captureItem = NSMenuItem(title: "Click Capture: \(captureStatus())", action: nil, keyEquivalent: "")
        captureItem.isEnabled = false
        menu.addItem(captureItem)
        menu.addItem(NSMenuItem.separator())

        let permissionTitle = permissions.isAccessibilityTrusted ? "Accessibility: Granted" : "Open Accessibility Settings..."
        let permissionItem = NSMenuItem(title: permissionTitle, action: #selector(openAccessibilitySettings), keyEquivalent: "")
        permissionItem.target = self
        permissionItem.isEnabled = true
        menu.addItem(permissionItem)

        menu.addItem(NSMenuItem.separator())
        let updatesConfigured = updatesAreConfigured()
        let updateItem = NSMenuItem(
            title: updatesConfigured ? "Check for Updates..." : "Updates: Not Configured",
            action: updatesConfigured ? #selector(checkForUpdates) : nil,
            keyEquivalent: ""
        )
        updateItem.target = self
        updateItem.isEnabled = updatesConfigured
        menu.addItem(updateItem)

        let quitItem = NSMenuItem(title: "Quit ClickLight", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func applyStatusItemAppearance(_ settings: ClickSettings) {
        guard let button = statusItem.button else { return }
        button.imagePosition = settings.showMenuBarText ? .imageLeading : .imageOnly
        button.title = settings.showMenuBarText ? "ClickLight" : ""
    }

    private func toggleItem(title: String, isOn: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = isOn ? .on : .off
        return item
    }

    private func submenu(
        title: String,
        options: [ClickNumericPreset],
        selected: Double,
        action: Selector
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu()
        let selectedPreset = options.first { abs($0.value - selected) < 0.01 }
        for option in options {
            let child = NSMenuItem(title: option.title, action: action, keyEquivalent: "")
            child.target = self
            child.representedObject = option.value
            child.state = selectedPreset?.value == option.value ? .on : .off
            menu.addItem(child)
        }
        if selectedPreset == nil {
            menu.addItem(NSMenuItem.separator())
            let custom = NSMenuItem(title: "Custom", action: nil, keyEquivalent: "")
            custom.state = .on
            custom.isEnabled = false
            menu.addItem(custom)
        }
        item.submenu = menu
        return item
    }

    private func colorSubmenu(selected: ClickColorPreset) -> NSMenuItem {
        let item = NSMenuItem(title: "Colors", action: nil, keyEquivalent: "")
        let menu = NSMenu()
        for preset in ClickColorPreset.allCases where preset != .custom {
            let child = NSMenuItem(title: preset.title, action: #selector(selectColor(_:)), keyEquivalent: "")
            child.target = self
            child.representedObject = preset.rawValue
            child.state = preset == selected ? .on : .off
            menu.addItem(child)
        }

        menu.addItem(NSMenuItem.separator())

        if selected == .custom {
            let selectedCustom = NSMenuItem(title: "Custom (Configured in Settings)", action: nil, keyEquivalent: "")
            selectedCustom.state = .on
            selectedCustom.isEnabled = false
            menu.addItem(selectedCustom)
        }

        let configureCustom = NSMenuItem(title: "Configure Custom Colors...", action: #selector(openSettings), keyEquivalent: "")
        configureCustom.target = self
        menu.addItem(configureCustom)

        item.submenu = menu
        return item
    }

    @objc private func toggleEnabled() {
        settingsStore.update { $0.isEnabled.toggle() }
    }

    @objc private func openSettings() {
        onOpenSettings()
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

    @objc private func toggleMiddleClick() {
        settingsStore.update { $0.showMiddleClick.toggle() }
    }

    @objc private func toggleDrag() {
        settingsStore.update { $0.showDrag.toggle() }
    }

    @objc private func toggleLaserPointer() {
        settingsStore.update { $0.showLaserPointer.toggle() }
    }

    @objc private func toggleMenuBarText() {
        settingsStore.update { $0.showMenuBarText.toggle() }
    }

    @objc private func toggleLaunchAtLogin() {
        let enabled = LaunchAtLoginState.toggledValue(currentlyEnabled: launchAtLogin.isEnabled)
        do {
            try launchAtLogin.setEnabled(enabled)
        } catch {
            NSLog("ClickLight: Failed to update launch at login: \(error)")
        }
        rebuildMenu()
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

    @objc private func selectColor(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let preset = ClickColorPreset(rawValue: rawValue)
        else { return }
        settingsStore.update { $0.colorPreset = preset }
    }

    @objc private func openAccessibilitySettings() {
        permissions.requestAccessibilityIfNeeded()
        permissions.openPrivacySettings()
    }

    @objc private func checkForUpdates() {
        onCheckForUpdates()
    }

    @objc private func quit() {
        onQuit()
    }
}
