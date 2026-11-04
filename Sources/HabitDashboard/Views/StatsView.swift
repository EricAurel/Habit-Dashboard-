import Charts
import HabitCore
import SwiftUI

/// Statistik-Fenster: Erfüllung pro Tag, Quoten pro Gewohnheit, Übungssummen.
struct StatsView: View {
    @EnvironmentObject var state: AppState
    @State private var range = 30
    @State private var selectedDate: Date?

    var body: some View {
        let stats = StatsCalculator(data: state.data)
        let streaks = state.streaks
        let days = stats.days(endingAt: state.today, count: range)
        let points = stats.dailyPoints(days)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker("Zeitraum", selection: $range) {
                    Text("7 Tage").tag(7)
                    Text("30 Tage").tag(30)
                    Text("90 Tage").tag(90)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                HStack(spacing: 12) {
                    StatTile(
                        title: "Gesamt-Streak",
                        value: "🔥 \(streaks.overallStreak(today: state.today))",
                        detail: "Rekord: \(streaks.longestOverallStreak(today: state.today)) Tage"
                    )
                    StatTile(
                        title: "Perfekte Tage",
                        value: "\(stats.perfectDays(days))",
                        detail: "von \(range) Tagen"
                    )
                    StatTile(
                        title: "Bewegungspausen",
                        value: "\(stats.totalBreaks(days))",
                        detail: "Streak: \(streaks.breakStreak(today: state.today)) Tage"
                    )
                }

                completionChart(points)
                habitTable(stats.habitSummaries(days, today: state.today))
                exerciseTable(stats.exerciseTotals(days))
            }
            .padding(24)
        }
        .frame(width: 580, height: 720)
    }

    // MARK: - Diagramm

    private func completionChart(_ points: [StatsCalculator.DayPoint]) -> some View {
        let selected = selectedDate.flatMap { date in points.first { Calendar.current.isDate($0.day.date(), inSameDayAs: date) } }
        let average = Self.average(points)

        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Erfüllung pro Tag")
            // Zeile über dem Diagramm: Durchschnitt oder der Tag unter dem Mauszeiger.
            Group {
                if let selected {
                    Text("\(selected.day.date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))): ")
                        + Text(selected.ratio.map { "\(Int(($0 * 100).rounded())) %" } ?? "–").bold()
                        + Text(" · \(selected.breaks) Pause\(selected.breaks == 1 ? "" : "n")")
                } else {
                    Text("Durchschnitt: ") + Text(average.map { "\(Int(($0 * 100).rounded())) %" } ?? "–").bold()
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Chart(points, id: \.self) { point in
                BarMark(
                    x: .value("Tag", point.day.date(), unit: .day),
                    y: .value("Erfüllt", (point.ratio ?? 0) * 100)
                )
                .cornerRadius(3)
                .foregroundStyle(Color.green.opacity(selected == nil || selected == point ? 1 : 0.35))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel {
                        if let v = value.as(Int.self) { Text("\(v) %") }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: 180)
        }
    }

    private static func average(_ points: [StatsCalculator.DayPoint]) -> Double? {
        let ratios = points.compactMap(\.ratio)
        guard !ratios.isEmpty else { return nil }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    // MARK: - Tabellen

    private func habitTable(_ summaries: [StatsCalculator.HabitSummary]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Gewohnheiten")
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                GridRow {
                    Text("Gewohnheit")
                    Text("Quote")
                    Text("")
                    Text("Aktuell")
                    Text("Rekord")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                ForEach(summaries) { summary in
                    GridRow {
                        Text("\(summary.habit.emoji) \(summary.habit.name)")
                            .lineLimit(1)
                        ProgressView(value: summary.rate)
                            .tint(Color.green)
                            .frame(width: 110)
                        Text("\(Int((summary.rate * 100).rounded())) %")
                            .monospacedDigit()
                            .gridColumnAlignment(.trailing)
                        Text("🔥 \(summary.currentStreak)")
                            .monospacedDigit()
                        HStack(spacing: 4) {
                            Text("\(summary.longestStreak)").monospacedDigit()
                            if let level = Milestones.reached(streak: summary.longestStreak) {
                                Text(Milestones.badge(for: level))
                                    .help("\(level)-Tage-Meilenstein erreicht")
                            }
                        }
                    }
                }
            }
        }
    }

    private func exerciseTable(_ totals: [StatsCalculator.ExerciseTotal]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Übungen")
            if totals.isEmpty {
                Text("Noch keine Übungen eingetragen. Trag im Pausen-Popup ein, was du geschafft hast.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                    GridRow {
                        Text("Übung")
                        Text("Gesamt")
                        Text("Einheiten")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    ForEach(totals) { total in
                        GridRow {
                            Text("\(total.emoji) \(total.name)")
                            Text(Self.format(total.total, unit: total.unit))
                                .monospacedDigit()
                                .fontWeight(.semibold)
                            Text("\(total.sessions)×")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    static func format(_ amount: Int, unit: ExerciseUnit) -> String {
        switch unit {
        case .reps:
            return "\(amount) Wdh."
        case .seconds:
            let minutes = amount / 60
            let seconds = amount % 60
            if minutes == 0 { return "\(seconds) Sek." }
            return seconds == 0 ? "\(minutes) Min." : "\(minutes) Min. \(seconds) Sek."
        }
    }
}

private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).font(.headline)
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.weight(.bold))
                .monospacedDigit()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
