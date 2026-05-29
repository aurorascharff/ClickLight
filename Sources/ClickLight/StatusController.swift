import AppKit

@MainActor
final class StatusController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settingsStore: SettingsStore
    private let permissions: PermissionController
    private let launchAtLogin: LaunchAtLoginManaging
    private let onCheckForUpdates: () -> Void
    private let updatesAreConfigured: () -> Bool
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void
    private let onMenuWillOpen: () -> Void
    private let onMenuDidClose: () -> Void

    init(
        settingsStore: SettingsStore,
        permissions: PermissionController,
        launchAtLogin: LaunchAtLoginManaging,
        onCheckForUpdates: @escaping () -> Void,
        updatesAreConfigured: @escaping () -> Bool,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onMenuWillOpen: @escaping () -> Void = {},
        onMenuDidClose: @escaping () -> Void = {}
    ) {
        self.settingsStore = settingsStore
        self.permissions = permissions
        self.launchAtLogin = launchAtLogin
        self.onCheckForUpdates = onCheckForUpdates
        self.updatesAreConfigured = updatesAreConfigured
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
        self.onMenuWillOpen = onMenuWillOpen
        self.onMenuDidClose = onMenuDidClose
        super.init()
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

    func dismissMenu() {
        statusItem.menu?.cancelTrackingWithoutAnimation()
        RunLoop.main.perform(inModes: [.common]) { [weak self] in
            MainActor.assumeIsolated {
                self?.statusItem.menu?.cancelTrackingWithoutAnimation()
            }
        }
    }

    private func dismissMenu(from item: NSMenuItem) {
        item.menu?.cancelTrackingWithoutAnimation()
        dismissMenu()
    }

    @objc private func settingsDidChange() {
        // Update the menu bar button immediately; the dropdown menu itself is
        // rebuilt lazily in menuNeedsUpdate(_:) so it always shows fresh state
        // the next time it opens. NSStatusItem menus don't repaint reliably
        // while tracking, so live mid-tracking refresh isn't attempted.
        applyStatusItemAppearance(settingsStore.settings)
    }

    private func rebuildMenu() {
        let menu = statusItem.menu ?? NSMenu()
        rebuildMenuItems(in: menu)
        menu.delegate = self
        if statusItem.menu !== menu {
            statusItem.menu = menu
        }
    }

    private func rebuildMenuItems(in menu: NSMenu) {
        let settings = settingsStore.settings
        menu.removeAllItems()
        StatusMenuConfiguration.apply(to: menu)

        menu.addItem(toggleItem(
            title: "Enabled",
            isOn: settings.isEnabled,
            action: #selector(toggleEnabled(_:)),
            shortcut: settings.shortcutBindings[.toggleEnabled]
        ))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(toggleItem(
            title: "Laser Pointer Mode",
            isOn: settings.showLaserPointer,
            action: #selector(toggleLaserPointer(_:)),
            shortcut: settings.shortcutBindings[.toggleLaserPointer]
        ))
        menu.addItem(toggleItem(
            title: "Show Live Keyboard Shortcuts",
            isOn: settings.showLiveKeyboardShortcuts,
            action: #selector(toggleLiveKeyboardShortcuts(_:))
        ))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(toggleItem(
            title: "Show Press",
            isOn: settings.showPress,
            action: #selector(togglePress(_:)),
            shortcut: settings.shortcutBindings[.toggleShowPress]
        ))
        menu.addItem(toggleItem(
            title: "Show Release",
            isOn: settings.showRelease,
            action: #selector(toggleRelease(_:)),
            shortcut: settings.shortcutBindings[.toggleShowRelease]
        ))
        menu.addItem(toggleItem(
            title: "Show Right Click",
            isOn: settings.showRightClick,
            action: #selector(toggleRightClick(_:)),
            shortcut: settings.shortcutBindings[.toggleShowRightClick]
        ))
        menu.addItem(toggleItem(
            title: "Show Middle Click",
            isOn: settings.showMiddleClick,
            action: #selector(toggleMiddleClick(_:)),
            shortcut: settings.shortcutBindings[.toggleShowMiddleClick]
        ))
        let showDragItem = toggleItem(
            title: "Show Drag",
            isOn: settings.showDrag,
            action: #selector(toggleDrag(_:)),
            shortcut: settings.shortcutBindings[.toggleShowDrag]
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

        let openSettingsItem = NSMenuItem(title: "Open Settings...", action: #selector(openSettings), keyEquivalent: ",")
        openSettingsItem.target = self
        menu.addItem(openSettingsItem)

        let permissionTitle = permissions.isAccessibilityTrusted ? "Accessibility: Granted" : "Open Accessibility Settings..."
        let permissionItem = NSMenuItem(title: permissionTitle, action: #selector(openAccessibilitySettings), keyEquivalent: "")
        permissionItem.target = self
        permissionItem.isEnabled = true
        menu.addItem(permissionItem)
        if settings.showLiveKeyboardShortcuts {
            let inputTitle = permissions.isInputMonitoringTrusted ? "Input Monitoring: Granted" : "Open Input Monitoring Settings..."
            let inputItem = NSMenuItem(title: inputTitle, action: #selector(openInputMonitoringSettings), keyEquivalent: "")
            inputItem.target = self
            inputItem.isEnabled = true
            menu.addItem(inputItem)
        }

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
    }

    private func applyStatusItemAppearance(_ settings: ClickSettings) {
        guard let button = statusItem.button else { return }
        button.imagePosition = settings.showMenuBarText ? .imageLeading : .imageOnly
        button.title = settings.showMenuBarText ? "ClickLight" : ""
    }

    private func toggleItem(
        title: String,
        isOn: Bool,
        action: Selector,
        shortcut: HotKeyBinding? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = isOn ? .on : .off
        applyShortcut(shortcut, to: item)
        return item
    }

    private func applyShortcut(_ shortcut: HotKeyBinding?, to item: NSMenuItem) {
        item.attributedTitle = nil
        guard let shortcut, let keyEquivalent = shortcut.menuKeyEquivalent else {
            item.keyEquivalent = ""
            item.keyEquivalentModifierMask = []
            return
        }
        item.keyEquivalent = keyEquivalent
        item.keyEquivalentModifierMask = shortcut.menuModifierFlags
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

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.isEnabled.toggle() }
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func togglePress(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.showPress.toggle() }
    }

    @objc private func toggleRelease(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.showRelease.toggle() }
    }

    @objc private func toggleRightClick(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.showRightClick.toggle() }
    }

    @objc private func toggleMiddleClick(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.showMiddleClick.toggle() }
    }

    @objc private func toggleDrag(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.showDrag.toggle() }
    }

    @objc private func toggleLaserPointer(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.showLaserPointer.toggle() }
    }

    @objc private func toggleLiveKeyboardShortcuts(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.showLiveKeyboardShortcuts.toggle() }
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

    @objc private func openInputMonitoringSettings() {
        permissions.requestInputMonitoringIfNeeded()
        permissions.openInputMonitoringSettings()
    }

    @objc private func checkForUpdates() {
        onCheckForUpdates()
    }

    @objc private func quit() {
        onQuit()
    }
}

extension StatusController: NSMenuDelegate {
    nonisolated func menuWillOpen(_ menu: NSMenu) {
        MainActor.assumeIsolated {
            onMenuWillOpen()
        }
    }

    nonisolated func menuDidClose(_ menu: NSMenu) {
        MainActor.assumeIsolated {
            onMenuDidClose()
        }
    }

    nonisolated func menuNeedsUpdate(_ menu: NSMenu) {
        MainActor.assumeIsolated {
            // Refresh the existing menu instance. Replacing statusItem.menu
            // while AppKit is opening it can fire menuDidClose for the old
            // menu and re-register global hotkeys before tracking actually
            // ends.
            guard let menu = statusItem.menu else { return }
            rebuildMenuItems(in: menu)
        }
    }
}
