import Foundation

struct ClickNumericPreset: Equatable {
    let title: String
    let value: Double
}

enum ClickSettingOptions {
    static let sizePresets: [ClickNumericPreset] = [
        .init(title: "Small", value: 44),
        .init(title: "Medium", value: 64),
        .init(title: "Large", value: 88),
        .init(title: "Huge", value: 116)
    ]

    static let intensityPresets: [ClickNumericPreset] = [
        .init(title: "Subtle", value: 0.28),
        .init(title: "Normal", value: 0.7),
        .init(title: "Bright", value: 1.0),
        .init(title: "Beacon", value: 1.35)
    ]

    static let durationPresets: [ClickNumericPreset] = [
        .init(title: "Snappy", value: 0.28),
        .init(title: "Normal", value: 0.48),
        .init(title: "Long", value: 0.72),
        .init(title: "Very Long", value: 1.0)
    ]

    static func matchingPreset(
        for value: CGFloat,
        in options: [ClickNumericPreset],
        tolerance: Double = 0.01
    ) -> ClickNumericPreset? {
        options.first { abs(Double(value) - $0.value) < tolerance }
    }

    static func matchingPreset(
        for value: TimeInterval,
        in options: [ClickNumericPreset],
        tolerance: Double = 0.01
    ) -> ClickNumericPreset? {
        options.first { abs(value - $0.value) < tolerance }
    }
}
