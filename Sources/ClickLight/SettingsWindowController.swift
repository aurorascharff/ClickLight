import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    private let viewModel: ClickLightSettingsViewModel

    init(
        settingsStore: SettingsStore,
        launchAtLogin: LaunchAtLoginManaging,
        permissions: PermissionController,
        hotKeyRegistrationIssuesProvider: @escaping () -> [ClickShortcutAction: String]
    ) {
        let viewModel = ClickLightSettingsViewModel(
            settingsStore: settingsStore,
            launchAtLogin: launchAtLogin,
            permissions: permissions,
            hotKeyRegistrationIssuesProvider: hotKeyRegistrationIssuesProvider
        )
        self.viewModel = viewModel

        let hosting = NSHostingController(rootView: ClickLightSettingsView(viewModel: viewModel))
        let window = NSWindow(contentViewController: hosting)
        window.title = "ClickLight Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 900, height: 580))
        window.minSize = NSSize(width: 820, height: 480)
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        viewModel.refreshSystemState()
    }

    func contains(_ screenPoint: NSPoint) -> Bool {
        guard let window, window.isVisible else { return false }
        return window.frame.contains(screenPoint)
    }
}

@MainActor
final class ClickLightSettingsViewModel: NSObject, ObservableObject {
    private let settingsStore: SettingsStore
    private let launchAtLogin: LaunchAtLoginManaging
    private let permissions: PermissionController
    private let hotKeyRegistrationIssuesProvider: () -> [ClickShortcutAction: String]

    @Published private(set) var settings: ClickSettings
    @Published private(set) var launchAtLoginEnabled: Bool = false
    @Published private(set) var accessibilityTrusted: Bool = false
    @Published private(set) var inputMonitoringTrusted: Bool = false
    @Published var launchAtLoginErrorMessage: String?
    @Published private(set) var shortcutErrors: [ClickShortcutAction: String] = [:]
    @Published private(set) var hotKeyRegistrationIssues: [ClickShortcutAction: String] = [:]

    init(
        settingsStore: SettingsStore,
        launchAtLogin: LaunchAtLoginManaging,
        permissions: PermissionController,
        hotKeyRegistrationIssuesProvider: @escaping () -> [ClickShortcutAction: String]
    ) {
        self.settingsStore = settingsStore
        self.launchAtLogin = launchAtLogin
        self.permissions = permissions
        self.hotKeyRegistrationIssuesProvider = hotKeyRegistrationIssuesProvider
        self.settings = settingsStore.settings
        super.init()
        self.launchAtLoginEnabled = launchAtLogin.isEnabled
        self.accessibilityTrusted = permissions.isAccessibilityTrusted
        self.inputMonitoringTrusted = permissions.isInputMonitoringTrusted
        self.shortcutErrors = Self.findShortcutConflicts(in: settings)
        self.hotKeyRegistrationIssues = hotKeyRegistrationIssuesProvider()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: SettingsStore.didChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotKeyRegistrationIssuesDidChange(_:)),
            name: AppDelegate.hotKeyRegistrationIssuesDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func settingsDidChange() {
        let latestSettings = settingsStore.settings
        if settings != latestSettings {
            settings = latestSettings
        }
        shortcutErrors = Self.findShortcutConflicts(in: latestSettings)
    }

    @objc private func appBecameActive() {
        refreshSystemState()
    }

    @objc private func hotKeyRegistrationIssuesDidChange(_ notification: Notification) {
        guard let serializedIssues = notification.userInfo?["issues"] as? [String: String] else {
            hotKeyRegistrationIssues = [:]
            return
        }

        var parsedIssues: [ClickShortcutAction: String] = [:]
        for (rawAction, message) in serializedIssues {
            guard let action = ClickShortcutAction(rawValue: rawAction) else { continue }
            parsedIssues[action] = message
        }
        hotKeyRegistrationIssues = parsedIssues
    }

    func refreshSystemState() {
        launchAtLoginEnabled = launchAtLogin.isEnabled
        accessibilityTrusted = permissions.isAccessibilityTrusted
        inputMonitoringTrusted = permissions.isInputMonitoringTrusted
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLogin.setEnabled(enabled)
            launchAtLoginErrorMessage = nil
        } catch {
            launchAtLoginErrorMessage = error.localizedDescription
        }
        launchAtLoginEnabled = launchAtLogin.isEnabled
    }

    func openAccessibilitySettings() {
        permissions.requestAccessibilityIfNeeded()
        permissions.openPrivacySettings()
    }

    func openInputMonitoringSettings() {
        permissions.requestInputMonitoringIfNeeded()
        permissions.openInputMonitoringSettings()
    }

    var sizePresetSelection: String {
        guard let preset = ClickSettingOptions.matchingPreset(for: settings.size, in: ClickSettingOptions.sizePresets) else {
            return "custom"
        }
        return String(preset.value)
    }

    var intensityPresetSelection: String {
        guard let preset = ClickSettingOptions.matchingPreset(for: settings.intensity, in: ClickSettingOptions.intensityPresets) else {
            return "custom"
        }
        return String(preset.value)
    }

    var durationPresetSelection: String {
        guard let preset = ClickSettingOptions.matchingPreset(for: settings.duration, in: ClickSettingOptions.durationPresets) else {
            return "custom"
        }
        return String(preset.value)
    }

    func update(_ mutate: (inout ClickSettings) -> Void) {
        var updatedSettings = settings
        mutate(&updatedSettings)
        apply(updatedSettings)
    }

    func applySizePresetSelection(_ selection: String) {
        guard let value = Double(selection) else { return }
        update { $0.size = CGFloat(value) }
    }

    func applyIntensityPresetSelection(_ selection: String) {
        guard let value = Double(selection) else { return }
        update { $0.intensity = CGFloat(value) }
    }

    func applyDurationPresetSelection(_ selection: String) {
        guard let value = Double(selection) else { return }
        update { $0.duration = value }
    }

    func applyCustomColor(_ color: NSColor) {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return }
        update {
            $0.customColorRed = rgb.redComponent
            $0.customColorGreen = rgb.greenComponent
            $0.customColorBlue = rgb.blueComponent
            $0.colorPreset = .custom
            $0.customColorMode = .all
        }
    }

    func applyCustomColor(_ color: NSColor, to target: CustomClickColorTarget) {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return }
        update {
            switch target {
            case .left:
                $0.customLeftColorRed = rgb.redComponent
                $0.customLeftColorGreen = rgb.greenComponent
                $0.customLeftColorBlue = rgb.blueComponent
            case .right:
                $0.customRightColorRed = rgb.redComponent
                $0.customRightColorGreen = rgb.greenComponent
                $0.customRightColorBlue = rgb.blueComponent
            case .middle:
                $0.customMiddleColorRed = rgb.redComponent
                $0.customMiddleColorGreen = rgb.greenComponent
                $0.customMiddleColorBlue = rgb.blueComponent
            case .drag:
                $0.customDragColorRed = rgb.redComponent
                $0.customDragColorGreen = rgb.greenComponent
                $0.customDragColorBlue = rgb.blueComponent
            }
            $0.colorPreset = .custom
            $0.customColorMode = .byClick
        }
    }

    func resetToDefaults() {
        apply(.defaults)
    }

    func shortcutBinding(for action: ClickShortcutAction) -> HotKeyBinding? {
        settings.shortcutBinding(for: action)
    }

    func shortcutError(for action: ClickShortcutAction) -> String? {
        shortcutErrors[action] ?? hotKeyRegistrationIssues[action]
    }

    var hasHotKeyRegistrationIssues: Bool {
        !hotKeyRegistrationIssues.isEmpty
    }

    var hotKeyRegistrationIssueSummary: [String] {
        ClickShortcutAction.allCases.compactMap { action in
            guard let issue = hotKeyRegistrationIssues[action] else { return nil }
            return "\(action.title): \(issue)"
        }
    }

    @discardableResult
    func updateShortcutBinding(_ binding: HotKeyBinding, for action: ClickShortcutAction) -> Bool {
        if let conflictingAction = conflictAction(for: binding, excluding: action) {
            let message = "Matches \(conflictingAction.title). Choose a unique shortcut."
            shortcutErrors[action] = message
            return false
        }

        shortcutErrors[action] = nil
        update { settings in
            settings.setShortcutBinding(binding, for: action)
        }
        return true
    }

    func resetShortcutBinding(for action: ClickShortcutAction) {
        update { settings in
            settings.resetShortcutBinding(for: action)
        }
    }

    func clearShortcutBinding(for action: ClickShortcutAction) {
        shortcutErrors[action] = nil
        update { settings in
            settings.clearShortcutBinding(for: action)
        }
    }

    func resetAllShortcutBindings() {
        update { settings in
            settings.resetAllShortcutBindings()
        }
    }

    private func apply(_ updatedSettings: ClickSettings) {
        guard settings != updatedSettings else { return }
        settings = updatedSettings
        shortcutErrors = Self.findShortcutConflicts(in: updatedSettings)

        DispatchQueue.main.async { [weak self] in
            guard let self, self.settings == updatedSettings else { return }
            self.settingsStore.settings = updatedSettings
        }
    }

    private func conflictAction(for binding: HotKeyBinding, excluding action: ClickShortcutAction) -> ClickShortcutAction? {
        ClickShortcutAction.allCases.first { candidate in
            guard candidate != action else { return false }
            return settings.shortcutBinding(for: candidate) == binding
        }
    }

    private static func findShortcutConflicts(in settings: ClickSettings) -> [ClickShortcutAction: String] {
        var errors: [ClickShortcutAction: String] = [:]

        for action in ClickShortcutAction.allCases {
            guard let binding = settings.shortcutBinding(for: action) else { continue }
            guard let other = ClickShortcutAction.allCases.first(where: {
                $0 != action && settings.shortcutBinding(for: $0) == binding
            }) else {
                continue
            }

            errors[action] = "Matches \(other.title). Choose a unique shortcut."
        }

        return errors
    }
}
