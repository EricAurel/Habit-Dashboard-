import Foundation

public enum ExerciseUnit: String, Codable, Sendable {
    case reps
    case seconds

    public var short: String {
        switch self {
        case .reps: return "×"
        case .seconds: return "Sek."
        }
    }
}

public struct Exercise: Hashable, Sendable, Identifiable {
    public var id: String { name }
    public let emoji: String
    public let name: String
    /// Vorgeschlagene Menge (Wiederholungen oder Sekunden).
    public let target: Int
    public let unit: ExerciseUnit
    /// z. B. "pro Bein" – Menge gilt je Seite.
    public let perSide: String?

    public init(emoji: String, name: String, target: Int, unit: ExerciseUnit = .reps, perSide: String? = nil) {
        self.emoji = emoji
        self.name = name
        self.target = target
        self.unit = unit
        self.perSide = perSide
    }

    /// Anzeige wie "25×", "60 Sek." oder "15× pro Bein".
    public var amount: String {
        let base = unit == .reps ? "\(target)×" : "\(target) Sek."
        return perSide.map { "\(base) \($0)" } ?? base
    }
}

/// Eine tatsächlich ausgeführte Übung mit der eingegebenen Menge.
public struct ExerciseEntry: Codable, Hashable, Sendable {
    public var name: String
    public var emoji: String
    public var amount: Int
    public var target: Int
    public var unit: ExerciseUnit

    public init(name: String, emoji: String, amount: Int, target: Int, unit: ExerciseUnit) {
        self.name = name
        self.emoji = emoji
        self.amount = amount
        self.target = target
        self.unit = unit
    }

    public init(exercise: Exercise, amount: Int) {
        self.init(name: exercise.name, emoji: exercise.emoji, amount: amount, target: exercise.target, unit: exercise.unit)
    }
}

/// Intensive Übungen ohne Ausrüstung, die neben dem Schreibtisch gehen.
public enum ExerciseCatalog {
    public static let all: [Exercise] = [
        Exercise(emoji: "🦵", name: "Kniebeugen", target: 25),
        Exercise(emoji: "💪", name: "Liegestütze", target: 20),
        Exercise(emoji: "🧱", name: "Plank", target: 60, unit: .seconds),
        Exercise(emoji: "🏃", name: "Hampelmänner", target: 40),
        Exercise(emoji: "🔥", name: "Burpees", target: 10),
        Exercise(emoji: "⛰️", name: "Mountain Climbers", target: 30),
        Exercise(emoji: "🚶", name: "Ausfallschritte", target: 15, perSide: "pro Bein"),
        Exercise(emoji: "🦘", name: "Jump Squats", target: 15),
        Exercise(emoji: "🪑", name: "Trizeps-Dips am Stuhl", target: 15),
        Exercise(emoji: "🧍", name: "Wandsitzen", target: 60, unit: .seconds),
        Exercise(emoji: "🦶", name: "Wadenheben", target: 30),
        Exercise(emoji: "🏋️", name: "Seitstütz", target: 30, unit: .seconds, perSide: "pro Seite"),
        Exercise(emoji: "🌉", name: "Glute Bridges", target: 20),
        Exercise(emoji: "🏃‍♀️", name: "High Knees", target: 45, unit: .seconds),
    ]

    public static func random<G: RandomNumberGenerator>(count: Int, using generator: inout G) -> [Exercise] {
        Array(all.shuffled(using: &generator).prefix(max(1, min(count, all.count))))
    }

    public static func random(count: Int) -> [Exercise] {
        var generator = SystemRandomNumberGenerator()
        return random(count: count, using: &generator)
    }
}
