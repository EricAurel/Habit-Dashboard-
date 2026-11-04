import Foundation

/// Speichert `HabitData` als JSON-Datei.
/// Standardort: ~/Library/Application Support/HabitDashboard/habits.json
public struct HabitPersistence: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
        return base
            .appendingPathComponent("HabitDashboard", isDirectory: true)
            .appendingPathComponent("habits.json")
    }

    /// Lädt die Daten; gibt nil zurück, wenn noch keine Datei existiert.
    public func load() throws -> HabitData? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let raw = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(HabitData.self, from: raw)
    }

    public func save(_ data: HabitData) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(data).write(to: fileURL, options: .atomic)
    }
}
