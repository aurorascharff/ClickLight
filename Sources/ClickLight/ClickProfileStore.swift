import AppKit
import Combine

struct ClickSettingsProfile: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var settings: ClickProfileSettings
    var createdAt: Date

    init(id: UUID, name: String, settings: ClickProfileSettings, createdAt: Date) {
        self.id = id
        self.name = name
        self.settings = settings
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case settings
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        settings = try container.decode(ClickProfileSettings.self, forKey: .settings)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? container.decodeIfPresent(Date.self, forKey: .updatedAt)
            ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(settings, forKey: .settings)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct ClickProfileSettings: Codable, Equatable {
    var showPress: Bool
    var showRelease: Bool
    var showRightClick: Bool
    var showMiddleClick: Bool
    var showDrag: Bool
    var showLaserPointer: Bool
    var showLiveKeyboardShortcuts: Bool
    var liveShortcutPosition: LiveShortcutPosition
    var liveShortcutSize: LiveShortcutSize
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
    var laserColorRed: CGFloat
    var laserColorGreen: CGFloat
    var laserColorBlue: CGFloat
    var laserInnerColorRed: CGFloat
    var laserInnerColorGreen: CGFloat
    var laserInnerColorBlue: CGFloat

    init(settings: ClickSettings) {
        self.showPress = settings.showPress
        self.showRelease = settings.showRelease
        self.showRightClick = settings.showRightClick
        self.showMiddleClick = settings.showMiddleClick
        self.showDrag = settings.showDrag
        self.showLaserPointer = settings.showLaserPointer
        self.showLiveKeyboardShortcuts = settings.showLiveKeyboardShortcuts
        self.liveShortcutPosition = settings.liveShortcutPosition
        self.liveShortcutSize = settings.liveShortcutSize
        self.size = settings.size
        self.intensity = settings.intensity
        self.duration = settings.duration
        self.colorPreset = settings.colorPreset
        self.customColorMode = settings.customColorMode
        self.customColorRed = settings.customColorRed
        self.customColorGreen = settings.customColorGreen
        self.customColorBlue = settings.customColorBlue
        self.customLeftColorRed = settings.customLeftColorRed
        self.customLeftColorGreen = settings.customLeftColorGreen
        self.customLeftColorBlue = settings.customLeftColorBlue
        self.customRightColorRed = settings.customRightColorRed
        self.customRightColorGreen = settings.customRightColorGreen
        self.customRightColorBlue = settings.customRightColorBlue
        self.customMiddleColorRed = settings.customMiddleColorRed
        self.customMiddleColorGreen = settings.customMiddleColorGreen
        self.customMiddleColorBlue = settings.customMiddleColorBlue
        self.customDragColorRed = settings.customDragColorRed
        self.customDragColorGreen = settings.customDragColorGreen
        self.customDragColorBlue = settings.customDragColorBlue
        self.laserColorRed = settings.laserColorRed
        self.laserColorGreen = settings.laserColorGreen
        self.laserColorBlue = settings.laserColorBlue
        self.laserInnerColorRed = settings.laserInnerColorRed
        self.laserInnerColorGreen = settings.laserInnerColorGreen
        self.laserInnerColorBlue = settings.laserInnerColorBlue
    }

    func apply(to settings: inout ClickSettings) {
        settings.showPress = showPress
        settings.showRelease = showRelease
        settings.showRightClick = showRightClick
        settings.showMiddleClick = showMiddleClick
        settings.showDrag = showDrag
        settings.showLaserPointer = showLaserPointer
        settings.showLiveKeyboardShortcuts = showLiveKeyboardShortcuts
        settings.liveShortcutPosition = liveShortcutPosition
        settings.liveShortcutSize = liveShortcutSize
        settings.size = size
        settings.intensity = intensity
        settings.duration = duration
        settings.colorPreset = colorPreset
        settings.customColorMode = customColorMode
        settings.customColorRed = customColorRed
        settings.customColorGreen = customColorGreen
        settings.customColorBlue = customColorBlue
        settings.customLeftColorRed = customLeftColorRed
        settings.customLeftColorGreen = customLeftColorGreen
        settings.customLeftColorBlue = customLeftColorBlue
        settings.customRightColorRed = customRightColorRed
        settings.customRightColorGreen = customRightColorGreen
        settings.customRightColorBlue = customRightColorBlue
        settings.customMiddleColorRed = customMiddleColorRed
        settings.customMiddleColorGreen = customMiddleColorGreen
        settings.customMiddleColorBlue = customMiddleColorBlue
        settings.customDragColorRed = customDragColorRed
        settings.customDragColorGreen = customDragColorGreen
        settings.customDragColorBlue = customDragColorBlue
        settings.laserColorRed = laserColorRed
        settings.laserColorGreen = laserColorGreen
        settings.laserColorBlue = laserColorBlue
        settings.laserInnerColorRed = laserInnerColorRed
        settings.laserInnerColorGreen = laserInnerColorGreen
        settings.laserInnerColorBlue = laserInnerColorBlue
    }
}

@MainActor
final class ClickProfileStore: ObservableObject {
    private enum Key {
        static let profiles = "settingsProfiles"
    }

    @Published private(set) var profiles: [ClickSettingsProfile]

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.profiles = Self.loadProfiles(from: defaults)
    }

    @discardableResult
    func saveProfile(named rawName: String, from settings: ClickSettings) -> ClickSettingsProfile? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let existing = profiles.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        let profile = ClickSettingsProfile(
            id: existing?.id ?? UUID(),
            name: name,
            settings: ClickProfileSettings(settings: settings),
            createdAt: existing?.createdAt ?? Date()
        )

        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        profiles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
        return profile
    }

    func delete(_ profile: ClickSettingsProfile) {
        profiles.removeAll { $0.id == profile.id }
        save()
    }

    func exportProfiles(to url: URL) throws {
        let exportEncoder = JSONEncoder()
        exportEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let export = ClickProfileExport(version: 1, profiles: profiles)
        try exportEncoder.encode(export).write(to: url, options: .atomic)
    }

    @discardableResult
    func importProfiles(from url: URL) throws -> Int {
        let data = try Data(contentsOf: url)
        let imported: [ClickSettingsProfile]
        if let export = try? decoder.decode(ClickProfileExport.self, from: data) {
            imported = export.profiles
        } else {
            imported = try decoder.decode([ClickSettingsProfile].self, from: data)
        }

        for profile in imported {
            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = profile
            } else if let index = profiles.firstIndex(where: {
                $0.name.caseInsensitiveCompare(profile.name) == .orderedSame
            }) {
                profiles[index] = profile
            } else {
                profiles.append(profile)
            }
        }
        profiles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
        return imported.count
    }

    private func save() {
        guard let encoded = try? encoder.encode(profiles) else { return }
        defaults.set(encoded, forKey: Key.profiles)
    }

    private static func loadProfiles(from defaults: UserDefaults) -> [ClickSettingsProfile] {
        guard let data = defaults.data(forKey: Key.profiles),
              let saved = try? JSONDecoder().decode([ClickSettingsProfile].self, from: data) else {
            return []
        }
        return saved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private struct ClickProfileExport: Codable {
    var version: Int
    var profiles: [ClickSettingsProfile]
}
