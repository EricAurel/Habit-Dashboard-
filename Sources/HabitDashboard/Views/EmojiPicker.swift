import SwiftUI

/// Dropdown-Menü zur Emoji-Auswahl, nach Themen gruppiert.
struct EmojiPicker: View {
    @Binding var selection: String

    struct Item: Hashable {
        let emoji: String
        let name: String
        init(_ emoji: String, _ name: String) { self.emoji = emoji; self.name = name }
    }

    struct Category: Hashable {
        let title: String
        let items: [Item]
        init(_ title: String, _ items: [Item]) { self.title = title; self.items = items }
    }

    static let categories: [Category] = [
        Category("Gesundheit", [
            Item("💧", "Wasser"), Item("🥗", "Gesund essen"), Item("🍎", "Obst"), Item("💊", "Vitamine"),
            Item("😴", "Schlafen"), Item("🚭", "Nicht rauchen"), Item("🦷", "Zahnpflege"), Item("☀️", "Sonnenlicht"),
        ]),
        Category("Bewegung", [
            Item("🏃", "Laufen"), Item("🚶", "Spazieren"), Item("🏋️", "Krafttraining"), Item("🧘", "Yoga"),
            Item("🚴", "Radfahren"), Item("🏊", "Schwimmen"), Item("🤸", "Dehnen"), Item("⚽", "Sport"),
        ]),
        Category("Geist & Lernen", [
            Item("📚", "Lesen"), Item("✍️", "Schreiben"), Item("🧠", "Lernen"), Item("🗣️", "Sprache"),
            Item("🎸", "Musik"), Item("🎨", "Kreativ"), Item("💻", "Coden"), Item("📝", "Tagebuch"),
        ]),
        Category("Achtsamkeit", [
            Item("🧘‍♂️", "Meditieren"), Item("🙏", "Dankbarkeit"), Item("🌿", "Natur"), Item("📵", "Handyfrei"),
            Item("🫁", "Atmen"), Item("❤️", "Selbstfürsorge"), Item("😊", "Lächeln"), Item("🌙", "Abendroutine"),
        ]),
        Category("Alltag", [
            Item("🧹", "Aufräumen"), Item("🛏️", "Bett machen"), Item("🍳", "Kochen"), Item("💰", "Sparen"),
            Item("📞", "Anrufen"), Item("🌱", "Pflanzen gießen"), Item("🐕", "Gassi gehen"), Item("✅", "Sonstiges"),
        ]),
    ]

    var body: some View {
        Menu {
            ForEach(Self.categories, id: \.self) { category in
                Section(category.title) {
                    ForEach(category.items, id: \.self) { item in
                        Button("\(item.emoji)  \(item.name)") { selection = item.emoji }
                    }
                }
            }
        } label: {
            Text(selection.isEmpty ? "✅" : selection)
                .font(.title3)
        }
        .menuIndicator(.visible)
        .fixedSize()
        .help("Emoji auswählen")
    }
}
