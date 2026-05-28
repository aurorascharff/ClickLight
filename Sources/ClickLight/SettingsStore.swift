import AppKit

struct ClickSettings: Equatable {
    var isEnabled: Bool
    var showPress: Bool
    var showRelease: Bool
    var showRightClick: Bool
    var showMiddleClick: Bool
    var showDrag: Bool
    var showLaserPointer: Bool
    var showMenuBarText: Bool
    var size: CGFloat
    var intensity: CGFloat
    var duration: TimeInterval
    var colorPreset: ClickColorPreset
    var customColorRed: CGFloat
    var customColorGreen: CGFloat
    var customColorBlue: CGFloat

    var customColor: NSColor {
        NSColor(
            calibratedRed: customColorRed.sanitizedColorComponent,
            green: customColorGreen.sanitizedColorComponent,
            blue: customColorBlue.sanitizedColorComponent,
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
        showMenuBarText: false,
        size: 64,
        intensity: 0.7,
        duration: 0.48,
        colorPreset: .default,
        customColorRed: 0.0,
        customColorGreen: 0.74,
        customColorBlue: 1.0
    )
}

enum ClickColorPreset: String, CaseIterable, Equatable {
    case `default`
    case custom
    case blue
    case green
    case purple
    case pink
    case orange
    case white

    var title: String {
        switch self {
        case .default:
            return "Default"
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
        static let showMenuBarText = "showMenuBarText"
        static let size = "size"
        static let intensity = "intensity"
        static let duration = "duration"
        static let colorPreset = "colorPreset"
        static let customColorRed = "customColorRed"
        static let customColorGreen = "customColorGreen"
        static let customColorBlue = "customColorBlue"
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
                showMenuBarText: defaults.bool(forKey: Key.showMenuBarText),
                size: CGFloat(defaults.double(forKey: Key.size)),
                intensity: CGFloat(defaults.double(forKey: Key.intensity)),
                duration: defaults.double(forKey: Key.duration),
                colorPreset: ClickColorPreset(rawValue: defaults.string(forKey: Key.colorPreset) ?? "") ?? .default,
                customColorRed: CGFloat(defaults.double(forKey: Key.customColorRed)).sanitizedColorComponent,
                customColorGreen: CGFloat(defaults.double(forKey: Key.customColorGreen)).sanitizedColorComponent,
                customColorBlue: CGFloat(defaults.double(forKey: Key.customColorBlue)).sanitizedColorComponent
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
            defaults.set(newValue.showMenuBarText, forKey: Key.showMenuBarText)
            defaults.set(Double(newValue.size), forKey: Key.size)
            defaults.set(Double(newValue.intensity), forKey: Key.intensity)
            defaults.set(newValue.duration, forKey: Key.duration)
            defaults.set(newValue.colorPreset.rawValue, forKey: Key.colorPreset)
            defaults.set(Double(newValue.customColorRed), forKey: Key.customColorRed)
            defaults.set(Double(newValue.customColorGreen), forKey: Key.customColorGreen)
            defaults.set(Double(newValue.customColorBlue), forKey: Key.customColorBlue)
            NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
        }
    }

    func update(_ mutate: (inout ClickSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
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
            Key.showMenuBarText: defaults.showMenuBarText,
            Key.size: Double(defaults.size),
            Key.intensity: Double(defaults.intensity),
            Key.duration: defaults.duration,
            Key.colorPreset: defaults.colorPreset.rawValue,
            Key.customColorRed: Double(defaults.customColorRed),
            Key.customColorGreen: Double(defaults.customColorGreen),
            Key.customColorBlue: Double(defaults.customColorBlue)
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
