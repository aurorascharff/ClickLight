import AppKit

struct ClickSettings: Equatable {
    var isEnabled: Bool
    var showPress: Bool
    var showRelease: Bool
    var showRightClick: Bool
    var showMiddleClick: Bool
    var showDrag: Bool
    var showLaserPointer: Bool
    var showLiveKeyboardShortcuts: Bool
    var showMenuBarText: Bool
    var size: CGFloat
    var intensity: CGFloat
    var duration: TimeInterval
    var colorPreset: ClickColorPreset
    var customColorMode: CustomClickColorMode
    var customColorRed: CGFloat
    var customColorGreen: CGFloat
    var customColorBlue: CGFloat
    var customLeftColorRed: CGFloat
    var customLeftColorGreen: CGFloat
    var customLeftColorBlue: CGFloat
    var customRightColorRed: CGFloat
    var customRightColorGreen: CGFloat
    var customRightColorBlue: CGFloat
    var customMiddleColorRed: CGFloat
    var customMiddleColorGreen: CGFloat
    var customMiddleColorBlue: CGFloat
    var customDragColorRed: CGFloat
    var customDragColorGreen: CGFloat
    var customDragColorBlue: CGFloat
    var toggleEnabledHotKey: HotKeyBinding?
    var toggleLaserPointerHotKey: HotKeyBinding?
    var toggleShowPressHotKey: HotKeyBinding?
    var toggleShowReleaseHotKey: HotKeyBinding?
    var toggleShowRightClickHotKey: HotKeyBinding?
    var toggleShowMiddleClickHotKey: HotKeyBinding?
    var toggleShowDragHotKey: HotKeyBinding?

    var customColor: NSColor {
        NSColor(
            calibratedRed: customColorRed.sanitizedColorComponent,
            green: customColorGreen.sanitizedColorComponent,
            blue: customColorBlue.sanitizedColorComponent,
            alpha: 1
        )
    }

    var customLeftColor: NSColor {
        NSColor(
            calibratedRed: customLeftColorRed.sanitizedColorComponent,
            green: customLeftColorGreen.sanitizedColorComponent,
            blue: customLeftColorBlue.sanitizedColorComponent,
            alpha: 1
        )
    }

    var customRightColor: NSColor {
        NSColor(
            calibratedRed: customRightColorRed.sanitizedColorComponent,
            green: customRightColorGreen.sanitizedColorComponent,
            blue: customRightColorBlue.sanitizedColorComponent,
            alpha: 1
        )
    }

    var customMiddleColor: NSColor {
        NSColor(
            calibratedRed: customMiddleColorRed.sanitizedColorComponent,
            green: customMiddleColorGreen.sanitizedColorComponent,
            blue: customMiddleColorBlue.sanitizedColorComponent,
            alpha: 1
        )
    }

    var customDragColor: NSColor {
        NSColor(
            calibratedRed: customDragColorRed.sanitizedColorComponent,
            green: customDragColorGreen.sanitizedColorComponent,
            blue: customDragColorBlue.sanitizedColorComponent,
            alpha: 1
        )
    }

    static let defaults = ClickSettings(
        isEnabled: true,
        showPress: true,
        showRelease: true,
        showRightClick: true,
        showMiddleClick: true,
        showDrag: true,
        showLaserPointer: false,
        showLiveKeyboardShortcuts: false,
        showMenuBarText: false,
        size: 64,
        intensity: 0.7,
        duration: 0.48,
        colorPreset: .default,
        customColorMode: .all,
        customColorRed: 0.0,
        customColorGreen: 0.74,
        customColorBlue: 1.0,
        customLeftColorRed: 0.0,
        customLeftColorGreen: 0.74,
        customLeftColorBlue: 1.0,
        customRightColorRed: 1.0,
        customRightColorGreen: 0.46,
        customRightColorBlue: 0.19,
        customMiddleColorRed: 0.27,
        customMiddleColorGreen: 0.92,
        customMiddleColorBlue: 0.58,
        customDragColorRed: 0.92,
        customDragColorGreen: 0.84,
        customDragColorBlue: 0.22,
        toggleEnabledHotKey: ClickShortcutAction.toggleEnabled.defaultBinding,
        toggleLaserPointerHotKey: ClickShortcutAction.toggleLaserPointer.defaultBinding,
        toggleShowPressHotKey: ClickShortcutAction.toggleShowPress.defaultBinding,
        toggleShowReleaseHotKey: ClickShortcutAction.toggleShowRelease.defaultBinding,
        toggleShowRightClickHotKey: ClickShortcutAction.toggleShowRightClick.defaultBinding,
        toggleShowMiddleClickHotKey: ClickShortcutAction.toggleShowMiddleClick.defaultBinding,
        toggleShowDragHotKey: ClickShortcutAction.toggleShowDrag.defaultBinding
    )

    var shortcutBindings: [ClickShortcutAction: HotKeyBinding] {
        Dictionary(uniqueKeysWithValues: ClickShortcutAction.allCases.compactMap { action in
            shortcutBinding(for: action).map { (action, $0) }
        })
    }

    func shortcutBinding(for action: ClickShortcutAction) -> HotKeyBinding? {
        switch action {
        case .toggleEnabled:
            return toggleEnabledHotKey
        case .toggleLaserPointer:
            return toggleLaserPointerHotKey
        case .toggleShowPress:
            return toggleShowPressHotKey
        case .toggleShowRelease:
            return toggleShowReleaseHotKey
        case .toggleShowRightClick:
            return toggleShowRightClickHotKey
        case .toggleShowMiddleClick:
            return toggleShowMiddleClickHotKey
        case .toggleShowDrag:
            return toggleShowDragHotKey
        }
    }

    mutating func setShortcutBinding(_ binding: HotKeyBinding?, for action: ClickShortcutAction) {
        switch action {
        case .toggleEnabled:
            toggleEnabledHotKey = binding
        case .toggleLaserPointer:
            toggleLaserPointerHotKey = binding
        case .toggleShowPress:
            toggleShowPressHotKey = binding
        case .toggleShowRelease:
            toggleShowReleaseHotKey = binding
        case .toggleShowRightClick:
            toggleShowRightClickHotKey = binding
        case .toggleShowMiddleClick:
            toggleShowMiddleClickHotKey = binding
        case .toggleShowDrag:
            toggleShowDragHotKey = binding
        }
    }

    mutating func resetShortcutBinding(for action: ClickShortcutAction) {
        setShortcutBinding(action.defaultBinding, for: action)
    }

    mutating func clearShortcutBinding(for action: ClickShortcutAction) {
        setShortcutBinding(nil, for: action)
    }

    mutating func resetAllShortcutBindings() {
        for action in ClickShortcutAction.allCases {
            resetShortcutBinding(for: action)
        }
    }

    static func defaultShortcutBinding(for action: ClickShortcutAction) -> HotKeyBinding? {
        action.defaultBinding
    }
}

enum CustomClickColorMode: String, CaseIterable, Equatable {
    case all
    case byClick

    var title: String {
        switch self {
        case .all:
            return "One Color"
        case .byClick:
            return "By Click"
        }
    }
}

enum CustomClickColorTarget {
    case left
    case right
    case middle
    case drag
}

enum ClickColorPreset: String, CaseIterable, Equatable {
    case `default`
    case primary
    case blue
    case green
    case purple
    case pink
    case orange
    case white
    case custom

    var title: String {
        switch self {
        case .default:
            return "Default"
        case .primary:
            return "Primary"
        case .custom:
            return "Custom"
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        case .purple:
            return "Purple"
        case .pink:
            return "Pink"
        case .orange:
            return "Orange"
        case .white:
            return "White"
        }
    }

    var color: NSColor? {
        switch self {
        case .default:
            return nil
        case .primary:
            return NSColor.controlAccentColor
        case .custom:
            return nil
        case .blue:
            return NSColor(calibratedRed: 0.0, green: 0.74, blue: 1.0, alpha: 1)
        case .green:
            return NSColor(calibratedRed: 0.2, green: 0.9, blue: 0.42, alpha: 1)
        case .purple:
            return NSColor(calibratedRed: 0.58, green: 0.36, blue: 1.0, alpha: 1)
        case .pink:
            return NSColor(calibratedRed: 1.0, green: 0.32, blue: 0.72, alpha: 1)
        case .orange:
            return NSColor(calibratedRed: 1.0, green: 0.46, blue: 0.19, alpha: 1)
        case .white:
            return NSColor(calibratedWhite: 1.0, alpha: 1)
        }
    }
}

@MainActor
final class SettingsStore {
    static let didChangeNotification = Notification.Name("ClickLightSettingsDidChange")

    private enum Key {
        static let isEnabled = "isEnabled"
        static let showPress = "showPress"
        static let showRelease = "showRelease"
        static let showRightClick = "showRightClick"
        static let showMiddleClick = "showMiddleClick"
        static let showDrag = "showDrag"
        static let showLaserPointer = "showLaserPointer"
        static let showLiveKeyboardShortcuts = "showLiveKeyboardShortcuts"
        static let showMenuBarText = "showMenuBarText"
        static let size = "size"
        static let intensity = "intensity"
        static let duration = "duration"
        static let colorPreset = "colorPreset"
        static let customColorMode = "customColorMode"
        static let customColorRed = "customColorRed"
        static let customColorGreen = "customColorGreen"
        static let customColorBlue = "customColorBlue"
        static let customLeftColorRed = "customLeftColorRed"
        static let customLeftColorGreen = "customLeftColorGreen"
        static let customLeftColorBlue = "customLeftColorBlue"
        static let customRightColorRed = "customRightColorRed"
        static let customRightColorGreen = "customRightColorGreen"
        static let customRightColorBlue = "customRightColorBlue"
        static let customMiddleColorRed = "customMiddleColorRed"
        static let customMiddleColorGreen = "customMiddleColorGreen"
        static let customMiddleColorBlue = "customMiddleColorBlue"
        static let customDragColorRed = "customDragColorRed"
        static let customDragColorGreen = "customDragColorGreen"
        static let customDragColorBlue = "customDragColorBlue"
        static let toggleEnabledHotKeyCode = "toggleEnabledHotKeyCode"
        static let toggleEnabledHotKeyModifiers = "toggleEnabledHotKeyModifiers"
        static let toggleEnabledHotKeyIsEnabled = "toggleEnabledHotKeyIsEnabled"
        static let toggleLaserPointerHotKeyCode = "toggleLaserPointerHotKeyCode"
        static let toggleLaserPointerHotKeyModifiers = "toggleLaserPointerHotKeyModifiers"
        static let toggleLaserPointerHotKeyIsEnabled = "toggleLaserPointerHotKeyIsEnabled"
        static let toggleShowPressHotKeyCode = "toggleShowPressHotKeyCode"
        static let toggleShowPressHotKeyModifiers = "toggleShowPressHotKeyModifiers"
        static let toggleShowPressHotKeyIsEnabled = "toggleShowPressHotKeyIsEnabled"
        static let toggleShowReleaseHotKeyCode = "toggleShowReleaseHotKeyCode"
        static let toggleShowReleaseHotKeyModifiers = "toggleShowReleaseHotKeyModifiers"
        static let toggleShowReleaseHotKeyIsEnabled = "toggleShowReleaseHotKeyIsEnabled"
        static let toggleShowRightClickHotKeyCode = "toggleShowRightClickHotKeyCode"
        static let toggleShowRightClickHotKeyModifiers = "toggleShowRightClickHotKeyModifiers"
        static let toggleShowRightClickHotKeyIsEnabled = "toggleShowRightClickHotKeyIsEnabled"
        static let toggleShowMiddleClickHotKeyCode = "toggleShowMiddleClickHotKeyCode"
        static let toggleShowMiddleClickHotKeyModifiers = "toggleShowMiddleClickHotKeyModifiers"
        static let toggleShowMiddleClickHotKeyIsEnabled = "toggleShowMiddleClickHotKeyIsEnabled"
        static let toggleShowDragHotKeyCode = "toggleShowDragHotKeyCode"
        static let toggleShowDragHotKeyModifiers = "toggleShowDragHotKeyModifiers"
        static let toggleShowDragHotKeyIsEnabled = "toggleShowDragHotKeyIsEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    var settings: ClickSettings {
        get {
            ClickSettings(
                isEnabled: defaults.bool(forKey: Key.isEnabled),
                showPress: defaults.bool(forKey: Key.showPress),
                showRelease: defaults.bool(forKey: Key.showRelease),
                showRightClick: defaults.bool(forKey: Key.showRightClick),
                showMiddleClick: defaults.bool(forKey: Key.showMiddleClick),
                showDrag: defaults.bool(forKey: Key.showDrag),
                showLaserPointer: defaults.bool(forKey: Key.showLaserPointer),
                showLiveKeyboardShortcuts: defaults.bool(forKey: Key.showLiveKeyboardShortcuts),
                showMenuBarText: defaults.bool(forKey: Key.showMenuBarText),
                size: CGFloat(defaults.double(forKey: Key.size)),
                intensity: CGFloat(defaults.double(forKey: Key.intensity)),
                duration: defaults.double(forKey: Key.duration),
                colorPreset: ClickColorPreset(rawValue: defaults.string(forKey: Key.colorPreset) ?? "") ?? .default,
                customColorMode: CustomClickColorMode(rawValue: defaults.string(forKey: Key.customColorMode) ?? "") ?? .all,
                customColorRed: CGFloat(defaults.double(forKey: Key.customColorRed)).sanitizedColorComponent,
                customColorGreen: CGFloat(defaults.double(forKey: Key.customColorGreen)).sanitizedColorComponent,
                customColorBlue: CGFloat(defaults.double(forKey: Key.customColorBlue)).sanitizedColorComponent,
                customLeftColorRed: CGFloat(defaults.double(forKey: Key.customLeftColorRed)).sanitizedColorComponent,
                customLeftColorGreen: CGFloat(defaults.double(forKey: Key.customLeftColorGreen)).sanitizedColorComponent,
                customLeftColorBlue: CGFloat(defaults.double(forKey: Key.customLeftColorBlue)).sanitizedColorComponent,
                customRightColorRed: CGFloat(defaults.double(forKey: Key.customRightColorRed)).sanitizedColorComponent,
                customRightColorGreen: CGFloat(defaults.double(forKey: Key.customRightColorGreen)).sanitizedColorComponent,
                customRightColorBlue: CGFloat(defaults.double(forKey: Key.customRightColorBlue)).sanitizedColorComponent,
                customMiddleColorRed: CGFloat(defaults.double(forKey: Key.customMiddleColorRed)).sanitizedColorComponent,
                customMiddleColorGreen: CGFloat(defaults.double(forKey: Key.customMiddleColorGreen)).sanitizedColorComponent,
                customMiddleColorBlue: CGFloat(defaults.double(forKey: Key.customMiddleColorBlue)).sanitizedColorComponent,
                customDragColorRed: CGFloat(defaults.double(forKey: Key.customDragColorRed)).sanitizedColorComponent,
                customDragColorGreen: CGFloat(defaults.double(forKey: Key.customDragColorGreen)).sanitizedColorComponent,
                customDragColorBlue: CGFloat(defaults.double(forKey: Key.customDragColorBlue)).sanitizedColorComponent,
                toggleEnabledHotKey: shortcutBinding(
                    keyCode: Key.toggleEnabledHotKeyCode,
                    modifiers: Key.toggleEnabledHotKeyModifiers,
                    isEnabled: Key.toggleEnabledHotKeyIsEnabled
                ),
                toggleLaserPointerHotKey: shortcutBinding(
                    keyCode: Key.toggleLaserPointerHotKeyCode,
                    modifiers: Key.toggleLaserPointerHotKeyModifiers,
                    isEnabled: Key.toggleLaserPointerHotKeyIsEnabled
                ),
                toggleShowPressHotKey: shortcutBinding(
                    keyCode: Key.toggleShowPressHotKeyCode,
                    modifiers: Key.toggleShowPressHotKeyModifiers,
                    isEnabled: Key.toggleShowPressHotKeyIsEnabled
                ),
                toggleShowReleaseHotKey: shortcutBinding(
                    keyCode: Key.toggleShowReleaseHotKeyCode,
                    modifiers: Key.toggleShowReleaseHotKeyModifiers,
                    isEnabled: Key.toggleShowReleaseHotKeyIsEnabled
                ),
                toggleShowRightClickHotKey: shortcutBinding(
                    keyCode: Key.toggleShowRightClickHotKeyCode,
                    modifiers: Key.toggleShowRightClickHotKeyModifiers,
                    isEnabled: Key.toggleShowRightClickHotKeyIsEnabled
                ),
                toggleShowMiddleClickHotKey: shortcutBinding(
                    keyCode: Key.toggleShowMiddleClickHotKeyCode,
                    modifiers: Key.toggleShowMiddleClickHotKeyModifiers,
                    isEnabled: Key.toggleShowMiddleClickHotKeyIsEnabled
                ),
                toggleShowDragHotKey: shortcutBinding(
                    keyCode: Key.toggleShowDragHotKeyCode,
                    modifiers: Key.toggleShowDragHotKeyModifiers,
                    isEnabled: Key.toggleShowDragHotKeyIsEnabled
                )
            )
        }
        set {
            defaults.set(newValue.isEnabled, forKey: Key.isEnabled)
            defaults.set(newValue.showPress, forKey: Key.showPress)
            defaults.set(newValue.showRelease, forKey: Key.showRelease)
            defaults.set(newValue.showRightClick, forKey: Key.showRightClick)
            defaults.set(newValue.showMiddleClick, forKey: Key.showMiddleClick)
            defaults.set(newValue.showDrag, forKey: Key.showDrag)
            defaults.set(newValue.showLaserPointer, forKey: Key.showLaserPointer)
            defaults.set(newValue.showLiveKeyboardShortcuts, forKey: Key.showLiveKeyboardShortcuts)
            defaults.set(newValue.showMenuBarText, forKey: Key.showMenuBarText)
            defaults.set(Double(newValue.size), forKey: Key.size)
            defaults.set(Double(newValue.intensity), forKey: Key.intensity)
            defaults.set(newValue.duration, forKey: Key.duration)
            defaults.set(newValue.colorPreset.rawValue, forKey: Key.colorPreset)
            defaults.set(newValue.customColorMode.rawValue, forKey: Key.customColorMode)
            defaults.set(Double(newValue.customColorRed), forKey: Key.customColorRed)
            defaults.set(Double(newValue.customColorGreen), forKey: Key.customColorGreen)
            defaults.set(Double(newValue.customColorBlue), forKey: Key.customColorBlue)
            defaults.set(Double(newValue.customLeftColorRed), forKey: Key.customLeftColorRed)
            defaults.set(Double(newValue.customLeftColorGreen), forKey: Key.customLeftColorGreen)
            defaults.set(Double(newValue.customLeftColorBlue), forKey: Key.customLeftColorBlue)
            defaults.set(Double(newValue.customRightColorRed), forKey: Key.customRightColorRed)
            defaults.set(Double(newValue.customRightColorGreen), forKey: Key.customRightColorGreen)
            defaults.set(Double(newValue.customRightColorBlue), forKey: Key.customRightColorBlue)
            defaults.set(Double(newValue.customMiddleColorRed), forKey: Key.customMiddleColorRed)
            defaults.set(Double(newValue.customMiddleColorGreen), forKey: Key.customMiddleColorGreen)
            defaults.set(Double(newValue.customMiddleColorBlue), forKey: Key.customMiddleColorBlue)
            defaults.set(Double(newValue.customDragColorRed), forKey: Key.customDragColorRed)
            defaults.set(Double(newValue.customDragColorGreen), forKey: Key.customDragColorGreen)
            defaults.set(Double(newValue.customDragColorBlue), forKey: Key.customDragColorBlue)
            saveShortcutBinding(newValue.toggleEnabledHotKey, keyCode: Key.toggleEnabledHotKeyCode, modifiers: Key.toggleEnabledHotKeyModifiers, isEnabled: Key.toggleEnabledHotKeyIsEnabled)
            saveShortcutBinding(newValue.toggleLaserPointerHotKey, keyCode: Key.toggleLaserPointerHotKeyCode, modifiers: Key.toggleLaserPointerHotKeyModifiers, isEnabled: Key.toggleLaserPointerHotKeyIsEnabled)
            saveShortcutBinding(newValue.toggleShowPressHotKey, keyCode: Key.toggleShowPressHotKeyCode, modifiers: Key.toggleShowPressHotKeyModifiers, isEnabled: Key.toggleShowPressHotKeyIsEnabled)
            saveShortcutBinding(newValue.toggleShowReleaseHotKey, keyCode: Key.toggleShowReleaseHotKeyCode, modifiers: Key.toggleShowReleaseHotKeyModifiers, isEnabled: Key.toggleShowReleaseHotKeyIsEnabled)
            saveShortcutBinding(newValue.toggleShowRightClickHotKey, keyCode: Key.toggleShowRightClickHotKeyCode, modifiers: Key.toggleShowRightClickHotKeyModifiers, isEnabled: Key.toggleShowRightClickHotKeyIsEnabled)
            saveShortcutBinding(newValue.toggleShowMiddleClickHotKey, keyCode: Key.toggleShowMiddleClickHotKeyCode, modifiers: Key.toggleShowMiddleClickHotKeyModifiers, isEnabled: Key.toggleShowMiddleClickHotKeyIsEnabled)
            saveShortcutBinding(newValue.toggleShowDragHotKey, keyCode: Key.toggleShowDragHotKeyCode, modifiers: Key.toggleShowDragHotKeyModifiers, isEnabled: Key.toggleShowDragHotKeyIsEnabled)
            NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
        }
    }

    func update(_ mutate: (inout ClickSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
    }

    private func shortcutBinding(keyCode: String, modifiers: String, isEnabled: String) -> HotKeyBinding? {
        guard defaults.bool(forKey: isEnabled) else { return nil }
        return HotKeyBinding(
            keyCode: defaults.integer(forKey: keyCode),
            carbonModifiers: defaults.integer(forKey: modifiers)
        )
    }

    private func saveShortcutBinding(_ binding: HotKeyBinding?, keyCode: String, modifiers: String, isEnabled: String) {
        defaults.set(binding != nil, forKey: isEnabled)
        guard let binding else { return }
        defaults.set(binding.keyCode, forKey: keyCode)
        defaults.set(binding.carbonModifiers, forKey: modifiers)
    }

    private func registerDefaults() {
        let defaults = ClickSettings.defaults
        self.defaults.register(defaults: [
            Key.isEnabled: defaults.isEnabled,
            Key.showPress: defaults.showPress,
            Key.showRelease: defaults.showRelease,
            Key.showRightClick: defaults.showRightClick,
            Key.showMiddleClick: defaults.showMiddleClick,
            Key.showDrag: defaults.showDrag,
            Key.showLaserPointer: defaults.showLaserPointer,
            Key.showLiveKeyboardShortcuts: defaults.showLiveKeyboardShortcuts,
            Key.showMenuBarText: defaults.showMenuBarText,
            Key.size: Double(defaults.size),
            Key.intensity: Double(defaults.intensity),
            Key.duration: defaults.duration,
            Key.colorPreset: defaults.colorPreset.rawValue,
            Key.customColorMode: defaults.customColorMode.rawValue,
            Key.customColorRed: Double(defaults.customColorRed),
            Key.customColorGreen: Double(defaults.customColorGreen),
            Key.customColorBlue: Double(defaults.customColorBlue),
            Key.customLeftColorRed: Double(defaults.customLeftColorRed),
            Key.customLeftColorGreen: Double(defaults.customLeftColorGreen),
            Key.customLeftColorBlue: Double(defaults.customLeftColorBlue),
            Key.customRightColorRed: Double(defaults.customRightColorRed),
            Key.customRightColorGreen: Double(defaults.customRightColorGreen),
            Key.customRightColorBlue: Double(defaults.customRightColorBlue),
            Key.customMiddleColorRed: Double(defaults.customMiddleColorRed),
            Key.customMiddleColorGreen: Double(defaults.customMiddleColorGreen),
            Key.customMiddleColorBlue: Double(defaults.customMiddleColorBlue),
            Key.customDragColorRed: Double(defaults.customDragColorRed),
            Key.customDragColorGreen: Double(defaults.customDragColorGreen),
            Key.customDragColorBlue: Double(defaults.customDragColorBlue),
            Key.toggleEnabledHotKeyCode: ClickShortcutAction.toggleEnabled.defaultBinding!.keyCode,
            Key.toggleEnabledHotKeyModifiers: ClickShortcutAction.toggleEnabled.defaultBinding!.carbonModifiers,
            Key.toggleEnabledHotKeyIsEnabled: true,
            Key.toggleLaserPointerHotKeyCode: 0,
            Key.toggleLaserPointerHotKeyModifiers: 0,
            Key.toggleLaserPointerHotKeyIsEnabled: false,
            Key.toggleShowPressHotKeyCode: 0,
            Key.toggleShowPressHotKeyModifiers: 0,
            Key.toggleShowPressHotKeyIsEnabled: false,
            Key.toggleShowReleaseHotKeyCode: 0,
            Key.toggleShowReleaseHotKeyModifiers: 0,
            Key.toggleShowReleaseHotKeyIsEnabled: false,
            Key.toggleShowRightClickHotKeyCode: 0,
            Key.toggleShowRightClickHotKeyModifiers: 0,
            Key.toggleShowRightClickHotKeyIsEnabled: false,
            Key.toggleShowMiddleClickHotKeyCode: 0,
            Key.toggleShowMiddleClickHotKeyModifiers: 0,
            Key.toggleShowMiddleClickHotKeyIsEnabled: false,
            Key.toggleShowDragHotKeyCode: 0,
            Key.toggleShowDragHotKeyModifiers: 0,
            Key.toggleShowDragHotKeyIsEnabled: false
        ])
    }
}

private extension CGFloat {
    /// Returns the value clamped to [0, 1], substituting 0 for NaN/infinite.
    var sanitizedColorComponent: CGFloat {
        guard isFinite else { return 0 }
        return Swift.min(1, Swift.max(0, self))
    }
}
