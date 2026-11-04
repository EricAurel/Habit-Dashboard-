import Foundation

/// Meilensteine für Streaks – dezent als Abzeichen angezeigt.
public enum Milestones {
    public static let levels = [7, 30, 100, 365]

    /// Höchster erreichter Meilenstein oder nil.
    public static func reached(streak: Int) -> Int? {
        levels.last { streak >= $0 }
    }

    /// `true`, wenn der Streak *genau* einen Meilenstein trifft (Moment zum Feiern).
    public static func isMilestone(_ streak: Int) -> Bool {
        levels.contains(streak)
    }

    public static func badge(for level: Int) -> String {
        switch level {
        case 365...: return "🏆"
        case 100...: return "🥇"
        case 30...: return "🥈"
        default: return "🥉"
        }
    }
}

/// Auswertungen über einen Zeitraum für die Statistik-Ansicht.
public struct StatsCalculator {
    public let data: HabitData
    public let calendar: Calendar

    public init(data: HabitData, calendar: Calendar = .current) {
        self.data = data
        self.calendar = calendar
    }

    /// Die letzten `count` Tage, ältester zuerst, endend mit `today`.
    public func days(endingAt today: Day, count: Int) -> [Day] {
        (0..<max(0, count)).reversed().map { today.adding(days: -$0, calendar: calendar) }
    }

    public struct DayPoint: Hashable, Sendable {
        public let day: Day
        /// 0...1 oder nil, wenn es an dem Tag keine Gewohnheiten gab.
        public let ratio: Double?
        public let breaks: Int
    }

    public func dailyPoints(_ days: [Day]) -> [DayPoint] {
        let streaks = StreakCalculator(data: data, calendar: calendar)
        return days.map { DayPoint(day: $0, ratio: streaks.completionRatio(on: $0), breaks: data.breaks(on: $0)) }
    }

    public struct HabitSummary: Hashable, Sendable, Identifiable {
        public var id: UUID { habit.id }
        public let habit: Habit
        public let doneDays: Int
        /// Tage im Zeitraum, an denen die Gewohnheit schon existierte.
        public let possibleDays: Int
        public let currentStreak: Int
        public let longestStreak: Int

        public var rate: Double { possibleDays > 0 ? Double(doneDays) / Double(possibleDays) : 0 }
    }

    public func habitSummaries(_ days: [Day], today: Day) -> [HabitSummary] {
        let streaks = StreakCalculator(data: data, calendar: calendar)
        return data.habits.map { habit in
            let possible = days.filter { $0 >= habit.createdDay }
            return HabitSummary(
                habit: habit,
                doneDays: possible.filter { data.isDone(habit.id, on: $0) }.count,
                possibleDays: possible.count,
                currentStreak: streaks.currentStreak(for: habit.id, today: today),
                longestStreak: streaks.longestStreak(for: habit.id)
            )
        }
    }

    public func perfectDays(_ days: [Day]) -> Int {
        let streaks = StreakCalculator(data: data, calendar: calendar)
        return days.filter { streaks.isPerfect($0) }.count
    }

    public func totalBreaks(_ days: [Day]) -> Int {
        days.reduce(0) { $0 + data.breaks(on: $1) }
    }

    public struct ExerciseTotal: Hashable, Sendable, Identifiable {
        public var id: String { name }
        public let name: String
        public let emoji: String
        public let unit: ExerciseUnit
        public let total: Int
        public let sessions: Int
    }

    /// Summe der geschafften Mengen pro Übung, größte zuerst.
    public func exerciseTotals(_ days: [Day]) -> [ExerciseTotal] {
        var totals: [String: ExerciseTotal] = [:]
        for day in days {
            for entry in data.exerciseEntries(on: day) {
                let old = totals[entry.name]
                totals[entry.name] = ExerciseTotal(
                    name: entry.name,
                    emoji: entry.emoji,
                    unit: entry.unit,
                    total: (old?.total ?? 0) + entry.amount,
                    sessions: (old?.sessions ?? 0) + 1
                )
            }
        }
        return totals.values.sorted { ($0.sessions, $0.total, $1.name) > ($1.sessions, $1.total, $0.name) }
    }
}
