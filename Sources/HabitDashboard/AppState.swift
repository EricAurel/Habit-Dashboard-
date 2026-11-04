import AppKit
import Foundation
import HabitCore
import SwiftUI

/// Zentrale, beobachtbare App-Daten. Jede Änderung wird sofort gespeichert.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var data: HabitData {
        didSet { if data != oldValue { persist() } }
    }
    @Published private(set) var today = Day.today()
    @Published private(set) var tracker: ActiveTimeTracker
    @Published var lastError: String?
    /// Gesetzt, solange eine fällige Pause wegen Vollbild/Call wartet.
    @Published private(set) var quietReason: QuietReason?

    private let persistence: HabitPersistence

    init(persistence: HabitPersistence = HabitPersistence(fileURL: HabitPersistence.defaultURL)) {
        self.persistence = persistence
        let loaded: HabitData
        var loadError: String?
        do {
            loaded = try persistence.load() ?? HabitData.starter(today: .today())
        } catch {
            loadError = "Daten konnten nicht geladen werden: \(error.localizedDescription)"
            loaded = HabitData.starter(today: .today())
        }
        data = loaded
        tracker = ActiveTimeTracker(
            interval: TimeInterval(loaded.settings.breakIntervalMinutes * 60),
            idleReset: TimeInterval(loaded.settings.idleResetMinutes * 60)
        )
        lastError = loadError
        if loadError == nil { persist() }
    }

    var streaks: StreakCalculator { StreakCalculator(data: data) }
    var settings: AppSettings { data.settings }

    // MARK: - Gewohnheiten

    func toggle(_ habit: Habit) {
        data.toggle(habit.id, on: today)
        // Dezente Feier: Sound, wenn das Abhaken genau einen Meilenstein trifft.
        if data.isDone(habit.id, on: today) {
            let streak = streaks.currentStreak(for: habit.id, today: today)
            let overall = streaks.overallStreak(today: today)
            if Milestones.isMilestone(streak) || Milestones.isMilestone(overall) {
                NSSound(named: "Glass")?.play()
            }
        }
    }

    func isDone(_ habit: Habit) -> Bool {
        data.isDone(habit.id, on: today)
    }

    func addHabit(name: String, emoji: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        data.addHabit(name: trimmed, emoji: emoji.trimmingCharacters(in: .whitespaces), today: today)
    }

    func removeHabit(_ habit: Habit) {
        data.removeHabit(habit.id)
    }

    func moveHabits(from source: IndexSet, to destination: Int) {
        data.habits.move(fromOffsets: source, toOffset: destination)
    }

    func rename(_ habit: Habit, name: String? = nil, emoji: String? = nil) {
        guard let index = data.habits.firstIndex(where: { $0.id == habit.id }) else { return }
        if let name { data.habits[index].name = name }
        if let emoji { data.habits[index].emoji = emoji }
    }

    // MARK: - Einstellungen

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        change(&data.settings)
        tracker.interval = TimeInterval(data.settings.breakIntervalMinutes * 60)
        tracker.idleReset = TimeInterval(data.settings.idleResetMinutes * 60)
    }

    // MARK: - Bewegungspausen

    /// Wird vom Aktivitätsmonitor aufgerufen. Gibt `true` zurück, wenn eine Pause fällig ist.
    func tick(elapsed: TimeInterval, idleSeconds: TimeInterval, quiet: QuietReason?) -> Bool {
        refreshToday()
        let due = tracker.tick(elapsed: elapsed, idleSeconds: idleSeconds, quiet: quiet != nil)
        let reason = tracker.isPending ? quiet : nil
        if reason != quietReason { quietReason = reason }
        return due
    }

    func resetActiveTime() {
        tracker.reset()
        quietReason = nil
    }

    func snooze() {
        tracker.snooze(seconds: TimeInterval(data.settings.snoozeMinutes * 60))
    }

    func logBreak(entries: [ExerciseEntry] = []) {
        refreshToday()
        data.logBreak(on: today, entries: entries)
        resetActiveTime()
    }

    func refreshToday() {
        let now = Day.today()
        if now != today { today = now }
    }

    // MARK: - Speichern

    private func persist() {
        do {
            try persistence.save(data)
        } catch {
            lastError = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
