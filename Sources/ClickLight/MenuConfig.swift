import Foundation

struct MenuItemConfig: Codable, Identifiable, Equatable {
    let id: String
    var isVisible: Bool
}

struct MenuGroupConfig: Codable, Identifiable, Equatable {
    let id: String
    var isVisible: Bool
    var items: [MenuItemConfig]

    static let defaults: [MenuGroupConfig] = [
        MenuGroupConfig(id: "toggle", isVisible: true, items: [
            MenuItemConfig(id: "enabled", isVisible: true)
        ]),
        MenuGroupConfig(id: "modes", isVisible: true, items: [
            MenuItemConfig(id: "laserPointer", isVisible: true),
            MenuItemConfig(id: "liveKeyboardShortcuts", isVisible: true)
        ]),
        MenuGroupConfig(id: "events", isVisible: true, items: [
            MenuItemConfig(id: "showPress", isVisible: true),
            MenuItemConfig(id: "showRelease", isVisible: true),
            MenuItemConfig(id: "showRightClick", isVisible: true),
            MenuItemConfig(id: "showMiddleClick", isVisible: true),
            MenuItemConfig(id: "showDrag", isVisible: true)
        ]),
        MenuGroupConfig(id: "menuBar", isVisible: true, items: [
            MenuItemConfig(id: "showMenuBarText", isVisible: true),
            MenuItemConfig(id: "showMenuBarClickCount", isVisible: true),
            MenuItemConfig(id: "launchAtLogin", isVisible: true)
        ]),
        MenuGroupConfig(id: "presets", isVisible: true, items: [
            MenuItemConfig(id: "size", isVisible: true),
            MenuItemConfig(id: "intensity", isVisible: true),
            MenuItemConfig(id: "duration", isVisible: true),
            MenuItemConfig(id: "colors", isVisible: true)
        ])
    ]

    // Merge saved layout with defaults, preserving order and adding any new groups/items.
    static func merged(saved: [MenuGroupConfig], defaults: [MenuGroupConfig]) -> [MenuGroupConfig] {
        var result = saved
        let savedGroupIds = Set(saved.map(\.id))
        for defaultGroup in defaults where !savedGroupIds.contains(defaultGroup.id) {
            result.append(defaultGroup)
        }
        result = result.map { savedGroup in
            guard let defaultGroup = defaults.first(where: { $0.id == savedGroup.id }) else {
                return savedGroup
            }
            var group = savedGroup
            let savedItemIds = Set(savedGroup.items.map(\.id))
            for defaultItem in defaultGroup.items where !savedItemIds.contains(defaultItem.id) {
                group.items.append(defaultItem)
            }
            return group
        }
        return result
    }
}

extension MenuItemConfig {
    var title: String {
        switch id {
        case "enabled": return "Enabled"
        case "laserPointer": return "Laser Pointer Mode"
        case "liveKeyboardShortcuts": return "Show Live Keyboard Shortcuts"
        case "showPress": return "Show Press"
        case "showRelease": return "Show Release"
        case "showRightClick": return "Show Right Click"
        case "showMiddleClick": return "Show Middle Click"
        case "showDrag": return "Show Drag"
        case "showMenuBarText": return "Show Menu Bar Text"
        case "showMenuBarClickCount": return "Show Click Count in Menu Bar"
        case "launchAtLogin": return "Launch at Login"
        case "size": return "Size"
        case "intensity": return "Intensity"
        case "duration": return "Duration"
        case "colors": return "Colors"
        default: return id
        }
    }
}

extension MenuGroupConfig {
    var title: String {
        switch id {
        case "toggle": return "Enable"
        case "modes": return "Modes"
        case "events": return "Events"
        case "menuBar": return "Menu Bar"
        case "presets": return "Style Presets"
        default: return id
        }
    }
}
