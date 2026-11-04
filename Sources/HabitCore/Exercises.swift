import Foundation

public struct Exercise: Hashable, Sendable, Identifiable {
    public var id: String { name }
    public let emoji: String
    public let name: String
    public let amount: String

    public init(emoji: String, name: String, amount: String) {
        self.emoji = emoji
        self.name = name
        self.amount = amount
    }
}

/// Übungen, die ohne Ausrüstung neben dem Schreibtisch gehen.
public enum ExerciseCatalog {
    public static let all: [Exercise] = [
        Exercise(emoji: "🦵", name: "Kniebeugen", amount: "15×"),
        Exercise(emoji: "💪", name: "Liegestütze", amount: "10×"),
        Exercise(emoji: "🧱", name: "Plank", amount: "30 Sek."),
        Exercise(emoji: "🏃", name: "Hampelmänner", amount: "20×"),
        Exercise(emoji: "🚶", name: "Ausfallschritte", amount: "10× pro Bein"),
        Exercise(emoji: "🪑", name: "Trizeps-Dips am Stuhl", amount: "10×"),
        Exercise(emoji: "🙆", name: "Schulterkreisen", amount: "je 10× vor & zurück"),
        Exercise(emoji: "🦶", name: "Wadenheben", amount: "20×"),
        Exercise(emoji: "🧘", name: "Vorbeuge / Dehnen", amount: "30 Sek."),
        Exercise(emoji: "🔄", name: "Hüftkreisen", amount: "je 10× pro Seite"),
        Exercise(emoji: "🧍", name: "Wandsitzen", amount: "30 Sek."),
        Exercise(emoji: "🌀", name: "Nacken dehnen", amount: "je 20 Sek. pro Seite"),
    ]

    public static func random<G: RandomNumberGenerator>(count: Int, using generator: inout G) -> [Exercise] {
        Array(all.shuffled(using: &generator).prefix(max(1, min(count, all.count))))
    }

    public static func random(count: Int) -> [Exercise] {
        var generator = SystemRandomNumberGenerator()
        return random(count: count, using: &generator)
    }
}
