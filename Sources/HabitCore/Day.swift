import Foundation

/// Ein Kalendertag ohne Uhrzeit (lokale Zeitzone). Wird als "yyyy-MM-dd" gespeichert.
public struct Day: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year ?? 1970, month: c.month ?? 1, day: c.day ?? 1)
    }

    public static func today(calendar: Calendar = .current) -> Day {
        Day(Date(), calendar: calendar)
    }

    /// Parst einen Schlüssel im Format "yyyy-MM-dd".
    public init?(key: String) {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    public var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public var description: String { key }

    /// Mittag des Tages – vermeidet Probleme bei Zeitumstellungen.
    public func date(in calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    public func adding(days: Int, calendar: Calendar = .current) -> Day {
        let shifted = calendar.date(byAdding: .day, value: days, to: date(in: calendar)) ?? date(in: calendar)
        return Day(shifted, calendar: calendar)
    }

    /// Wochentag-Index relativ zu `calendar.firstWeekday` (0 = erster Tag der Woche).
    public func weekdayIndex(calendar: Calendar = .current) -> Int {
        let weekday = calendar.component(.weekday, from: date(in: calendar))
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    public static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
