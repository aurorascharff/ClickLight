import AppKit

struct ClickSettings: Equatable {
    var isEnabled: Bool
    var showPress: Bool
    var showRelease: Bool
    var showRightClick: Bool
    var showDrag: Bool
    var size: CGFloat
    var intensity: CGFloat
    var duration: TimeInterval

    static let defaults = ClickSettings(
        isEnabled: true,
        showPress: true,
        showRelease: true,
        showRightClick: true,
        showDrag: true,
        size: 64,
        intensity: 0.9,
        duration: 0.48
    )
}

@MainActor
final class SettingsStore {
    static let didChangeNotification = Notification.Name("ClickLightSettingsDidChange")

    private enum Key {
        static let isEnabled = "isEnabled"
        static let showPress = "showPress"
        static let showRelease = "showRelease"
        static let showRightClick = "showRightClick"
        static let showDrag = "showDrag"
        static let size = "size"
        static let intensity = "intensity"
        static let duration = "duration"
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
                showDrag: defaults.bool(forKey: Key.showDrag),
                size: CGFloat(defaults.double(forKey: Key.size)),
                intensity: CGFloat(defaults.double(forKey: Key.intensity)),
                duration: defaults.double(forKey: Key.duration)
            )
        }
        set {
            defaults.set(newValue.isEnabled, forKey: Key.isEnabled)
            defaults.set(newValue.showPress, forKey: Key.showPress)
            defaults.set(newValue.showRelease, forKey: Key.showRelease)
            defaults.set(newValue.showRightClick, forKey: Key.showRightClick)
            defaults.set(newValue.showDrag, forKey: Key.showDrag)
            defaults.set(Double(newValue.size), forKey: Key.size)
            defaults.set(Double(newValue.intensity), forKey: Key.intensity)
            defaults.set(newValue.duration, forKey: Key.duration)
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
            Key.showDrag: defaults.showDrag,
            Key.size: Double(defaults.size),
            Key.intensity: Double(defaults.intensity),
            Key.duration: defaults.duration
        ])
    }
}
