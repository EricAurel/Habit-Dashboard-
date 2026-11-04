import XCTest
@testable import HabitCore

final class StreakTests: XCTestCase {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        c.firstWeekday = 2 // Montag
        return c
    }()

    let today = Day(year: 2026, month: 11, day: 4) // Mittwoch

    func day(_ offset: Int) -> Day { today.adding(days: offset, calendar: calendar) }

    func testDayArithmeticAcrossMonthAndDST() {
        XCTAssertEqual(Day(year: 2026, month: 3, day: 1).adding(days: -1, calendar: calendar), Day(year: 2026, month: 2, day: 28))
        // Zeitumstellung Ende Oktober
        XCTAssertEqual(Day(year: 2026, month: 10, day: 24).adding(days: 2, calendar: calendar), Day(year: 2026, month: 10, day: 26))
        XCTAssertEqual(Day(key: "2026-11-04"), today)
        XCTAssertEqual(today.key, "2026-11-04")
        XCTAssertEqual(today.weekdayIndex(calendar: calendar), 2) // Mo=0, Di=1, Mi=2
    }

    func testHabitStreakSurvivesUnfinishedToday() {
        var data = HabitData()
        let habit = data.addHabit(name: "Lesen", emoji: "📚", today: day(-10))
        for offset in -3 ... -1 { data.toggle(habit.id, on: day(offset)) }
        let calc = StreakCalculator(data: data, calendar: calendar)

        XCTAssertEqual(calc.currentStreak(for: habit.id, today: today), 3, "Heute noch offen bricht den Streak nicht")

        data.toggle(habit.id, on: today)
        XCTAssertEqual(StreakCalculator(data: data, calendar: calendar).currentStreak(for: habit.id, today: today), 4)
    }

    func testHabitStreakBreaksOnMissedDay() {
        var data = HabitData()
        let habit = data.addHabit(name: "Lesen", emoji: "📚", today: day(-10))
        data.toggle(habit.id, on: day(-5))
        data.toggle(habit.id, on: day(-4))
        data.toggle(habit.id, on: day(-2))
        let calc = StreakCalculator(data: data, calendar: calendar)
        XCTAssertEqual(calc.currentStreak(for: habit.id, today: today), 0)
        XCTAssertEqual(calc.longestStreak(for: habit.id), 2)
    }

    func testToggleTwiceRemovesCompletion() {
        var data = HabitData()
        let habit = data.addHabit(name: "Wasser", emoji: "💧", today: today)
        data.toggle(habit.id, on: today)
        XCTAssertTrue(data.isDone(habit.id, on: today))
        data.toggle(habit.id, on: today)
        XCTAssertFalse(data.isDone(habit.id, on: today))
        XCTAssertTrue(data.completions.isEmpty)
    }

    func testOverallStreakOnlyCountsHabitsThatExisted() {
        var data = HabitData()
        let a = data.addHabit(name: "A", emoji: "A", today: day(-5))
        let b = data.addHabit(name: "B", emoji: "B", today: day(-1)) // erst gestern angelegt
        for offset in -3 ... -2 { data.toggle(a.id, on: day(offset)) }
        data.toggle(a.id, on: day(-1))
        data.toggle(b.id, on: day(-1))
        let calc = StreakCalculator(data: data, calendar: calendar)

        XCTAssertEqual(calc.completionRatio(on: day(-2)), 1)
        XCTAssertEqual(calc.completionRatio(on: today), 0)
        XCTAssertNil(calc.completionRatio(on: day(-20)))
        XCTAssertEqual(calc.overallStreak(today: today), 3)
        XCTAssertEqual(calc.longestOverallStreak(today: today), 3)
    }

    func testRemovingHabitCleansCompletions() {
        var data = HabitData()
        let a = data.addHabit(name: "A", emoji: "A", today: today)
        data.toggle(a.id, on: today)
        data.removeHabit(a.id)
        XCTAssertTrue(data.habits.isEmpty)
        XCTAssertTrue(data.completions.isEmpty)
    }

    func testBreakStreak() {
        var data = HabitData()
        data.logBreak(on: day(-2))
        data.logBreak(on: day(-1))
        data.logBreak(on: day(-1))
        XCTAssertEqual(data.breaks(on: day(-1)), 2)
        XCTAssertEqual(StreakCalculator(data: data, calendar: calendar).breakStreak(today: today), 2)
    }

    func testHeatmapGrid() {
        let columns = HeatmapGrid.columns(endingAt: today, weeks: 3, calendar: calendar)
        XCTAssertEqual(columns.count, 3)
        XCTAssertTrue(columns.allSatisfy { $0.count == 7 })
        XCTAssertEqual(columns[2][2], today)           // Mittwoch der aktuellen Woche
        XCTAssertNil(columns[2][3])                    // Donnerstag liegt in der Zukunft
        XCTAssertEqual(columns[0][0], Day(year: 2026, month: 10, day: 19)) // Montag vor 2 Wochen
    }
}

final class ActiveTimeTrackerTests: XCTestCase {
    func testPromptsAfterIntervalOfActivity() {
        var tracker = ActiveTimeTracker(interval: 60 * 60, idleReset: 5 * 60)
        var prompted = false
        for _ in 0 ..< 239 { prompted = tracker.tick(elapsed: 15, idleSeconds: 2) || prompted }
        XCTAssertFalse(prompted)
        XCTAssertTrue(tracker.tick(elapsed: 15, idleSeconds: 2))
        XCTAssertEqual(tracker.activeSeconds, 0)
    }

    func testIdleResetsCounter() {
        var tracker = ActiveTimeTracker(interval: 3600, idleReset: 300)
        _ = tracker.tick(elapsed: 15, idleSeconds: 0)
        _ = tracker.tick(elapsed: 15, idleSeconds: 0)
        XCTAssertEqual(tracker.activeSeconds, 30)
        XCTAssertFalse(tracker.tick(elapsed: 15, idleSeconds: 301))
        XCTAssertEqual(tracker.activeSeconds, 0)
    }

    func testLongGapBetweenTicksCountsAsBreak() {
        var tracker = ActiveTimeTracker(interval: 3600, idleReset: 300)
        _ = tracker.tick(elapsed: 15, idleSeconds: 0)
        XCTAssertFalse(tracker.tick(elapsed: 2 * 3600, idleSeconds: 0)) // Ruhezustand
        XCTAssertEqual(tracker.activeSeconds, 0)
    }

    func testSnooze() {
        var tracker = ActiveTimeTracker(interval: 3600, idleReset: 300)
        tracker.snooze(seconds: 600)
        XCTAssertEqual(tracker.remainingSeconds, 600)
    }
}

final class PersistenceTests: XCTestCase {
    func testRoundTripAndForwardCompatibleDecoding() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("habits.json")
        let store = HabitPersistence(fileURL: url)
        XCTAssertNil(try store.load())

        var data = HabitData.starter(today: Day(year: 2026, month: 11, day: 4))
        data.toggle(data.habits[0].id, on: Day(year: 2026, month: 11, day: 4))
        data.settings.breakIntervalMinutes = 45
        try store.save(data)
        XCTAssertEqual(try store.load(), data)

        // Ältere Datei ohne neue Felder lässt sich trotzdem lesen.
        let legacy = #"{"habits": [], "settings": {"breakIntervalMinutes": 30}}"#
        let decoded = try JSONDecoder().decode(HabitData.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded.settings.breakIntervalMinutes, 30)
        XCTAssertEqual(decoded.settings.idleResetMinutes, 5)
        XCTAssertTrue(decoded.exerciseBreaks.isEmpty)
    }

    func testLogBreakStoresEnteredAmounts() {
        var data = HabitData()
        let day = Day(year: 2026, month: 11, day: 4)
        let squats = ExerciseCatalog.all.first { $0.name == "Kniebeugen" }!
        let plank = ExerciseCatalog.all.first { $0.name == "Plank" }!
        data.logBreak(on: day, entries: [
            ExerciseEntry(exercise: squats, amount: 30),
            ExerciseEntry(exercise: plank, amount: 0), // nicht gemacht
        ])
        XCTAssertEqual(data.breaks(on: day), 1)
        XCTAssertEqual(data.exerciseEntries(on: day).map(\.amount), [30])
        XCTAssertEqual(squats.amount, "25×")
        XCTAssertEqual(plank.amount, "60 Sek.")
    }

    func testRandomExercisesAreUnique() {
        let picked = ExerciseCatalog.random(count: 3)
        XCTAssertEqual(picked.count, 3)
        XCTAssertEqual(Set(picked).count, 3)
    }
}
