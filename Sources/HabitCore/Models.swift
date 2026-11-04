import Foundation

public struct Habit: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var emoji: String
    /// Ab diesem Tag zählt die Gewohnheit für den Gesamt-Streak ("yyyy-MM-dd").
    public var createdOn: String

    public init(id: UUID = UUID(), name: String, emoji: String, createdOn: Day) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.createdOn = createdOn.key
    }

    public var createdDay: Day { Day(key: createdOn) ?? Day(year: 1970, month: 1, day: 1) }
}

public struct AppSettings: Codable, Equatable, Sendable {
    /// Aktive Minuten am Rechner bis zur Bewegungspause.
    public var breakIntervalMinutes: Int = 60
    /// Nach so vielen Minuten ohne Maus/Tastatur beginnt der Zähler von vorn.
    public var idleResetMinutes: Int = 5
    public var snoozeMinutes: Int = 10
    public var exercisesPerBreak: Int = 3
    public var showDesktopWidget: Bool = true

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        breakIntervalMinutes = try c.decodeIfPresent(Int.self, forKey: .breakIntervalMinutes) ?? d.breakIntervalMinutes
        idleResetMinutes = try c.decodeIfPresent(Int.self, forKey: .idleResetMinutes) ?? d.idleResetMinutes
        snoozeMinutes = try c.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? d.snoozeMinutes
        exercisesPerBreak = try c.decodeIfPresent(Int.self, forKey: .exercisesPerBreak) ?? d.exercisesPerBreak
        showDesktopWidget = try c.decodeIfPresent(Bool.self, forKey: .showDesktopWidget) ?? d.showDesktopWidget
    }
}

/// Alle gespeicherten Daten der App.
public struct HabitData: Codable, Equatable, Sendable {
    public var habits: [Habit] = []
    /// Tag ("yyyy-MM-dd") -> IDs der erledigten Gewohnheiten.
    public var completions: [String: Set<UUID>] = [:]
    /// Tag ("yyyy-MM-dd") -> Anzahl erledigter Bewegungspausen.
    public var exerciseBreaks: [String: Int] = [:]
    /// Tag ("yyyy-MM-dd") -> tatsächlich ausgeführte Übungen.
    public var exerciseLog: [String: [ExerciseEntry]] = [:]
    public var settings = AppSettings()

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        habits = try c.decodeIfPresent([Habit].self, forKey: .habits) ?? []
        completions = try c.decodeIfPresent([String: Set<UUID>].self, forKey: .completions) ?? [:]
        exerciseBreaks = try c.decodeIfPresent([String: Int].self, forKey: .exerciseBreaks) ?? [:]
        exerciseLog = try c.decodeIfPresent([String: [ExerciseEntry]].self, forKey: .exerciseLog) ?? [:]
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
    }

    /// Startdaten beim allerersten Start.
    public static func starter(today: Day) -> HabitData {
        var data = HabitData()
        data.habits = [
            Habit(name: "2 L Wasser trinken", emoji: "💧", createdOn: today),
            Habit(name: "20 Min. lesen", emoji: "📚", createdOn: today),
            Habit(name: "Meditieren", emoji: "🧘", createdOn: today),
            Habit(name: "Spaziergang", emoji: "🚶", createdOn: today),
        ]
        return data
    }

    // MARK: - Gewohnheiten

    public func isDone(_ habitID: UUID, on day: Day) -> Bool {
        completions[day.key]?.contains(habitID) ?? false
    }

    public mutating func toggle(_ habitID: UUID, on day: Day) {
        var set = completions[day.key] ?? []
        if set.contains(habitID) {
            set.remove(habitID)
        } else {
            set.insert(habitID)
        }
        completions[day.key] = set.isEmpty ? nil : set
    }

    @discardableResult
    public mutating func addHabit(name: String, emoji: String, today: Day) -> Habit {
        let habit = Habit(name: name, emoji: emoji.isEmpty ? "✅" : emoji, createdOn: today)
        habits.append(habit)
        return habit
    }

    public mutating func removeHabit(_ habitID: UUID) {
        habits.removeAll { $0.id == habitID }
        for (key, set) in completions {
            var updated = set
            updated.remove(habitID)
            completions[key] = updated.isEmpty ? nil : updated
        }
    }

    public mutating func moveHabit(from source: Int, to destination: Int) {
        guard habits.indices.contains(source) else { return }
        let habit = habits.remove(at: source)
        habits.insert(habit, at: min(max(destination, 0), habits.count))
    }

    /// Gewohnheiten, die an diesem Tag bereits existierten.
    public func activeHabits(on day: Day) -> [Habit] {
        habits.filter { $0.createdDay <= day }
    }

    // MARK: - Bewegungspausen

    public func breaks(on day: Day) -> Int {
        exerciseBreaks[day.key] ?? 0
    }

    /// Zählt eine Bewegungspause und speichert die eingegebenen Mengen (0 wird ignoriert).
    public mutating func logBreak(on day: Day, entries: [ExerciseEntry] = []) {
        exerciseBreaks[day.key, default: 0] += 1
        let done = entries.filter { $0.amount > 0 }
        if !done.isEmpty {
            exerciseLog[day.key, default: []].append(contentsOf: done)
        }
    }

    public func exerciseEntries(on day: Day) -> [ExerciseEntry] {
        exerciseLog[day.key] ?? []
    }
}
