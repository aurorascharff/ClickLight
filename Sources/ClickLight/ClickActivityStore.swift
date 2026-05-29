import Foundation
import Combine
import QuartzCore

struct ClickActivityDay: Codable, Equatable, Identifiable {
    let id: String
    var primaryClicks: Int
    var secondaryClicks: Int
    var middleClicks: Int
    var drags: Int

    var totalClicks: Int {
        primaryClicks + secondaryClicks + middleClicks
    }
}

@MainActor
final class ClickActivityStore: ObservableObject {
    private enum Key {
        static let days = "clickActivityDays"
    }

    @Published private(set) var days: [ClickActivityDay]

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var recentEvents: [ClickEvent] = []
    private var hasRecordedCurrentDrag = false

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar
        self.days = Self.loadDays(from: defaults)
        pruneAndSave()
    }

    var lastSevenDays: [ClickActivityDay] {
        (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                return nil
            }
            let id = dayID(for: date)
            return days.first(where: { $0.id == id }) ?? Self.emptyDay(id: id)
        }
    }

    var today: ClickActivityDay {
        let id = dayID(for: Date())
        return days.first(where: { $0.id == id }) ?? Self.emptyDay(id: id)
    }

    func record(_ event: ClickEvent) {
        guard shouldAccept(event) else { return }

        switch event.kind {
        case .leftDown:
            hasRecordedCurrentDrag = false
            add { $0.primaryClicks += 1 }
        case .rightDown:
            hasRecordedCurrentDrag = false
            add { $0.secondaryClicks += 1 }
        case .middleDown:
            hasRecordedCurrentDrag = false
            add { $0.middleClicks += 1 }
        case .drag where !hasRecordedCurrentDrag:
            hasRecordedCurrentDrag = true
            add { $0.drags += 1 }
        case .leftUp, .rightUp, .middleUp:
            hasRecordedCurrentDrag = false
        case .drag, .move:
            break
        }
    }

    func reset() {
        days = []
        defaults.removeObject(forKey: Key.days)
    }

    func label(for day: ClickActivityDay) -> String {
        guard let date = date(from: day.id) else { return day.id }
        if calendar.isDateInToday(date) {
            return "Today"
        }
        return date.formatted(.dateTime.weekday(.abbreviated))
    }

    func accessibilityLabel(for day: ClickActivityDay) -> String {
        let dateLabel = date(from: day.id)?.formatted(date: .complete, time: .omitted) ?? day.id
        return "\(dateLabel), \(day.totalClicks) clicks"
    }

    private func add(_ update: (inout ClickActivityDay) -> Void) {
        let id = dayID(for: Date())
        if let index = days.firstIndex(where: { $0.id == id }) {
            update(&days[index])
        } else {
            var day = Self.emptyDay(id: id)
            update(&day)
            days.append(day)
        }
        pruneAndSave()
    }

    private func shouldAccept(_ event: ClickEvent) -> Bool {
        let now = CACurrentMediaTime()
        recentEvents = recentEvents.filter { now - $0.timestamp < 0.1 }
        let duplicate = recentEvents.contains {
            $0.kind == event.kind &&
            abs($0.location.x - event.location.x) < 3 &&
            abs($0.location.y - event.location.y) < 3
        }
        if !duplicate {
            recentEvents.append(event)
        }
        return !duplicate
    }

    private func pruneAndSave() {
        guard let cutoff = calendar.date(byAdding: .day, value: -6, to: Date()) else { return }
        let cutoffID = dayID(for: cutoff)
        days = days.filter { $0.id >= cutoffID }.sorted { $0.id < $1.id }
        guard let encoded = try? encoder.encode(days) else { return }
        defaults.set(encoded, forKey: Key.days)
    }

    private func dayID(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private func date(from id: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: id)
    }

    private static func loadDays(from defaults: UserDefaults) -> [ClickActivityDay] {
        guard let data = defaults.data(forKey: Key.days),
              let saved = try? JSONDecoder().decode([ClickActivityDay].self, from: data) else {
            return []
        }
        return saved
    }

    private static func emptyDay(id: String) -> ClickActivityDay {
        ClickActivityDay(id: id, primaryClicks: 0, secondaryClicks: 0, middleClicks: 0, drags: 0)
    }
}
