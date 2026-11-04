import Foundation

/// Berechnet Streaks und Tagesquoten.
///
/// Regel: Ein noch nicht erledigter *heutiger* Tag bricht den Streak nicht –
/// man hat ja bis Mitternacht Zeit. Der Streak zählt dann bis gestern.
public struct StreakCalculator {
    public let data: HabitData
    public let calendar: Calendar

    /// Schutz gegen Endlosschleifen bei sehr alten Daten.
    static let maxLookback = 3650

    public init(data: HabitData, calendar: Calendar = .current) {
        self.data = data
        self.calendar = calendar
    }

    // MARK: - Pro Gewohnheit

    public func currentStreak(for habitID: UUID, today: Day) -> Int {
        Self.currentRun(today: today, calendar: calendar) { data.isDone(habitID, on: $0) }
    }

    public func longestStreak(for habitID: UUID) -> Int {
        let days = data.completions
            .filter { $0.value.contains(habitID) }
            .compactMap { Day(key: $0.key) }
        return longestRun(in: days)
    }

    // MARK: - Gesamt

    /// Anteil erledigter Gewohnheiten (0...1) oder nil, wenn es an dem Tag keine gab.
    public func completionRatio(on day: Day) -> Double? {
        let active = data.activeHabits(on: day)
        guard !active.isEmpty else { return nil }
        let done = active.filter { data.isDone($0.id, on: day) }.count
        return Double(done) / Double(active.count)
    }

    /// Ein perfekter Tag: Alle an dem Tag existierenden Gewohnheiten sind erledigt.
    public func isPerfect(_ day: Day) -> Bool {
        completionRatio(on: day) == 1
    }

    public func overallStreak(today: Day) -> Int {
        Self.currentRun(today: today, calendar: calendar) { isPerfect($0) }
    }

    public func longestOverallStreak(today: Day) -> Int {
        guard let first = data.habits.map(\.createdDay).min() else { return 0 }
        var best = 0
        var run = 0
        var day = first
        var steps = 0
        while day <= today && steps < Self.maxLookback {
            if isPerfect(day) {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
            day = day.adding(days: 1, calendar: calendar)
            steps += 1
        }
        return best
    }

    // MARK: - Bewegungspausen

    public func breakStreak(today: Day) -> Int {
        Self.currentRun(today: today, calendar: calendar) { data.breaks(on: $0) > 0 }
    }

    // MARK: - Helfer

    static func currentRun(today: Day, calendar: Calendar, isComplete: (Day) -> Bool) -> Int {
        var day = isComplete(today) ? today : today.adding(days: -1, calendar: calendar)
        var count = 0
        while count < maxLookback && isComplete(day) {
            count += 1
            day = day.adding(days: -1, calendar: calendar)
        }
        return count
    }

    func longestRun(in days: [Day]) -> Int {
        let sorted = Set(days).sorted()
        var best = 0
        var run = 0
        var previous: Day?
        for day in sorted {
            if let previous, previous.adding(days: 1, calendar: calendar) == day {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }
}

/// Raster für die Heatmap: Spalten = Wochen, Zeilen = Wochentage.
public enum HeatmapGrid {
    /// Liefert `weeks` Spalten zu je 7 Tagen; Tage nach `today` sind nil.
    public static func columns(endingAt today: Day, weeks: Int, calendar: Calendar = .current) -> [[Day?]] {
        let startOfThisWeek = today.adding(days: -today.weekdayIndex(calendar: calendar), calendar: calendar)
        let start = startOfThisWeek.adding(days: -7 * (weeks - 1), calendar: calendar)
        return (0..<weeks).map { week in
            (0..<7).map { weekday in
                let day = start.adding(days: week * 7 + weekday, calendar: calendar)
                return day <= today ? day : nil
            }
        }
    }
}
