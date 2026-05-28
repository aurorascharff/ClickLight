import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    private let viewModel: ClickLightSettingsViewModel

    init(
        settingsStore: SettingsStore,
        launchAtLogin: LaunchAtLoginManaging,
        permissions: PermissionController
    ) {
        let viewModel = ClickLightSettingsViewModel(
            settingsStore: settingsStore,
            launchAtLogin: launchAtLogin,
            permissions: permissions
        )
        self.viewModel = viewModel

        let hosting = NSHostingController(rootView: ClickLightSettingsView(viewModel: viewModel))
        let window = NSWindow(contentViewController: hosting)
        window.title = "ClickLight Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 760, height: 520))
        window.minSize = NSSize(width: 700, height: 480)
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

    @Published private(set) var settings: ClickSettings
    @Published private(set) var launchAtLoginEnabled: Bool = false
    @Published private(set) var accessibilityTrusted: Bool = false
    @Published var launchAtLoginErrorMessage: String?

    init(
        settingsStore: SettingsStore,
        launchAtLogin: LaunchAtLoginManaging,
        permissions: PermissionController
    ) {
        self.settingsStore = settingsStore
        self.launchAtLogin = launchAtLogin
        self.permissions = permissions
        self.settings = settingsStore.settings
        super.init()
        self.launchAtLoginEnabled = launchAtLogin.isEnabled
        self.accessibilityTrusted = permissions.isAccessibilityTrusted
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: SettingsStore.didChangeNotification,
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
    }

    @objc private func appBecameActive() {
        refreshSystemState()
    }

    func refreshSystemState() {
        launchAtLoginEnabled = launchAtLogin.isEnabled
        accessibilityTrusted = permissions.isAccessibilityTrusted
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

    private func apply(_ updatedSettings: ClickSettings) {
        guard settings != updatedSettings else { return }
        settings = updatedSettings

        DispatchQueue.main.async { [weak self] in
            guard let self, self.settings == updatedSettings else { return }
            self.settingsStore.settings = updatedSettings
        }
    }
}
