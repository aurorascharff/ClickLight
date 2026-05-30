import AppKit
import Combine

@MainActor
final class StatusController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settingsStore: SettingsStore
    private let profileStore: ClickProfileStore
    private let activityStore: ClickActivityStore
    private let permissions: PermissionController
    private let launchAtLogin: LaunchAtLoginManaging
    private let onCheckForUpdates: () -> Void
    private let updatesAreConfigured: () -> Bool
    private let onOpenSettings: (SettingsPane?) -> Void
    private let onQuit: () -> Void
    private let onMenuWillOpen: () -> Void
    private let onMenuDidClose: () -> Void
    private var activityObserver: AnyCancellable?

    init(
        settingsStore: SettingsStore,
        profileStore: ClickProfileStore,
        activityStore: ClickActivityStore,
        permissions: PermissionController,
        launchAtLogin: LaunchAtLoginManaging,
        onCheckForUpdates: @escaping () -> Void,
        updatesAreConfigured: @escaping () -> Bool,
        onOpenSettings: @escaping (SettingsPane?) -> Void,
        onQuit: @escaping () -> Void,
        onMenuWillOpen: @escaping () -> Void = {},
        onMenuDidClose: @escaping () -> Void = {}
    ) {
        self.settingsStore = settingsStore
        self.profileStore = profileStore
        self.activityStore = activityStore
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
        activityObserver = activityStore.$days.sink { [weak self] _ in
            self?.applyStatusItemAppearance(self?.settingsStore.settings ?? .defaults)
        }
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
            shortcut: settings.shortcutBinding(for: .toggleEnabled)
        ))
        menu.addItem(.separator())

        menu.addItem(toggleItem(
            title: "Laser Pointer Mode",
            isOn: settings.showLaserPointer,
            action: #selector(toggleLaserPointer(_:)),
            shortcut: settings.shortcutBinding(for: .toggleLaserPointer)
        ))
        menu.addItem(toggleItem(
            title: "Show Live Keyboard Shortcuts",
            isOn: settings.showLiveKeyboardShortcuts,
            action: #selector(toggleLiveKeyboardShortcuts(_:)),
            shortcut: settings.shortcutBinding(for: .toggleLiveKeyboardShortcuts)
        ))
        menu.addItem(.separator())

        if settings.showEventControlsInMenu {
            menu.addItem(toggleItem(
                title: "Show Press",
                isOn: settings.showPress,
                action: #selector(togglePress(_:)),
                shortcut: settings.shortcutBinding(for: .toggleShowPress)
            ))
            menu.addItem(toggleItem(
                title: "Show Release",
                isOn: settings.showRelease,
                action: #selector(toggleRelease(_:)),
                shortcut: settings.shortcutBinding(for: .toggleShowRelease)
            ))
            menu.addItem(toggleItem(
                title: "Show Right Click",
                isOn: settings.showRightClick,
                action: #selector(toggleRightClick(_:)),
                shortcut: settings.shortcutBinding(for: .toggleShowRightClick)
            ))
            menu.addItem(toggleItem(
                title: "Show Middle Click",
                isOn: settings.showMiddleClick,
                action: #selector(toggleMiddleClick(_:)),
                shortcut: settings.shortcutBinding(for: .toggleShowMiddleClick)
            ))
            let showDragItem = toggleItem(
                title: "Show Drag",
                isOn: settings.showDrag,
                action: #selector(toggleDrag(_:)),
                shortcut: settings.shortcutBinding(for: .toggleShowDrag)
            )
            showDragItem.isEnabled = !settings.showLaserPointer
            menu.addItem(showDragItem)
            menu.addItem(.separator())
        }

        if settings.showStyleControlsInMenu {
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
            menu.addItem(.separator())
        }

        if settings.showProfilesInMenu {
            menu.addItem(profilesSubmenu(settings: settings))
            menu.addItem(.separator())
        }

        if settings.showMenuBarControlsInMenu {
            menu.addItem(toggleItem(
                title: "Show Menu Bar Text",
                isOn: settings.showMenuBarText,
                action: #selector(toggleMenuBarText)
            ))
            menu.addItem(toggleItem(
                title: "Show Click Count in Menu Bar",
                isOn: settings.showMenuBarClickCount,
                action: #selector(toggleMenuBarClickCount)
            ))
            menu.addItem(.separator())
        }

        if settings.showLaunchAtLoginInMenu {
            menu.addItem(toggleItem(
                title: "Launch at Login",
                isOn: launchAtLogin.isEnabled,
                action: #selector(toggleLaunchAtLogin)
            ))
            menu.addItem(.separator())
        }

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

        menu.addItem(.separator())
        let updatesConfigured = updatesAreConfigured()
        let updateItem = NSMenuItem(
            title: updatesConfigured ? "Check for Updates..." : "Updates: Not Configured",
            action: updatesConfigured ? #selector(checkForUpdates) : nil,
            keyEquivalent: ""
        )
        updateItem.target = self
        updateItem.isEnabled = updatesConfigured
        menu.addItem(updateItem)

        let aboutItem = NSMenuItem(title: "About ClickLight", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit ClickLight", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func applyStatusItemAppearance(_ settings: ClickSettings) {
        guard let button = statusItem.button else { return }
        var titleParts: [String] = []
        if settings.showMenuBarText {
            titleParts.append("ClickLight")
        }
        if settings.showMenuBarClickCount {
            titleParts.append(compactCount(activityStore.today.totalClicks))
        }
        button.imagePosition = titleParts.isEmpty ? .imageOnly : .imageLeading
        button.title = titleParts.joined(separator: " ")
    }

    private func compactCount(_ value: Int) -> String {
        value.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)))
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

        let configureCustom = NSMenuItem(title: "Configure Custom Colors...", action: #selector(openVisualStyleSettings), keyEquivalent: "")
        configureCustom.target = self
        menu.addItem(configureCustom)

        item.submenu = menu
        return item
    }

    private func profilesSubmenu(settings: ClickSettings) -> NSMenuItem {
        let item = NSMenuItem(title: "Profiles", action: nil, keyEquivalent: "")
        let menu = NSMenu()
        let currentSettings = ClickProfileSettings(settings: settings)

        if profileStore.profiles.isEmpty {
            let emptyItem = NSMenuItem(title: "No Profiles Saved", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for profile in profileStore.profiles {
                let child = NSMenuItem(title: profile.name, action: #selector(selectProfile(_:)), keyEquivalent: "")
                child.target = self
                child.representedObject = profile.id.uuidString
                child.state = profile.settings == currentSettings ? .on : .off
                child.isEnabled = profile.settings != currentSettings
                menu.addItem(child)
            }
        }

        menu.addItem(.separator())
        let manageItem = NSMenuItem(title: "Manage Profiles...", action: #selector(openProfileSettings), keyEquivalent: "")
        manageItem.target = self
        menu.addItem(manageItem)

        item.submenu = menu
        return item
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        dismissMenu(from: sender)
        settingsStore.update { $0.isEnabled.toggle() }
    }

    @objc private func openSettings() {
        onOpenSettings(nil)
    }

    @objc private func openProfileSettings() {
        onOpenSettings(.profiles)
    }

    @objc private func openVisualStyleSettings() {
        onOpenSettings(.style)
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

    @objc private func toggleMenuBarClickCount() {
        settingsStore.update { $0.showMenuBarClickCount.toggle() }
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

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let profileID = UUID(uuidString: rawValue),
            let profile = profileStore.profiles.first(where: { $0.id == profileID })
        else { return }
        dismissMenu(from: sender)
        settingsStore.update { settings in
            profile.settings.apply(to: &settings)
        }
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

    @objc private func showAbout() {
        let credits = NSMutableAttributedString(string: "Source on GitHub")
        credits.addAttributes(
            [
                .link: URL(string: "https://github.com/aurorascharff/ClickLight")!,
                .foregroundColor: NSColor.linkColor
            ],
            range: NSRange(location: 0, length: credits.length)
        )
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
        NSApp.activate(ignoringOtherApps: true)
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
