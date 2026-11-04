import HabitCore
import SwiftUI

/// Das Widget auf dem Schreibtisch.
struct DesktopWidgetView: View {
    @EnvironmentObject var state: AppState
    var onEdit: () -> Void = {}

    var body: some View {
        let streaks = state.streaks
        let habits = state.data.habits
        let doneCount = habits.filter { state.isDone($0) }.count

        VStack(alignment: .leading, spacing: 14) {
            header(streak: streaks.overallStreak(today: state.today), done: doneCount, total: habits.count)

            if habits.isEmpty {
                Button("Erste Gewohnheit anlegen …", action: onEdit)
                    .buttonStyle(.link)
            } else {
                VStack(spacing: 6) {
                    ForEach(habits) { habit in
                        HabitRow(
                            habit: habit,
                            isDone: state.isDone(habit),
                            streak: streaks.currentStreak(for: habit.id, today: state.today)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                state.toggle(habit)
                            }
                        }
                    }
                }
            }

            HeatmapView(streaks: streaks, today: state.today)

            BreakFooter(
                breaksToday: state.data.breaks(on: state.today),
                breakStreak: streaks.breakStreak(today: state.today),
                tracker: state.tracker
            )
        }
        .padding(18)
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12))
        )
        .contextMenu {
            Button("Gewohnheiten bearbeiten …", action: onEdit)
        }
    }

    private func header(streak: Int, done: Int, total: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.today.date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.headline)
                Text(total == 0 ? "Keine Gewohnheiten" : "\(done) von \(total) erledigt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            StreakBadge(count: streak, large: true)
                .help("Tage in Folge, an denen alle Gewohnheiten erledigt wurden")
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let isDone: Bool
    let streak: Int
    let onToggle: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                CheckBox(isOn: isDone)
                Text(habit.emoji)
                Text(habit.name)
                    .strikethrough(isDone, color: .secondary)
                    .foregroundStyle(isDone ? Color.secondary : Color.primary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                StreakBadge(count: streak, large: false)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(hovering ? 0.08 : 0.0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct CheckBox: View {
    let isOn: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(isOn ? Color.green : Color.secondary.opacity(0.6), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isOn ? Color.green : Color.clear)
                )
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 20, height: 20)
        .scaleEffect(isOn ? 1.0 : 0.95)
    }
}

struct StreakBadge: View {
    let count: Int
    let large: Bool

    var body: some View {
        HStack(spacing: 2) {
            Text("🔥")
                .grayscale(count == 0 ? 1 : 0)
                .opacity(count == 0 ? 0.4 : 1)
            Text("\(count)")
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .font(large ? .title2.weight(.bold) : .callout.weight(.semibold))
        .foregroundStyle(count == 0 ? Color.secondary : Color.primary)
    }
}

struct HeatmapView: View {
    let streaks: StreakCalculator
    let today: Day
    private let weeks = 15
    private let cell: CGFloat = 12

    var body: some View {
        let columns = HeatmapGrid.columns(endingAt: today, weeks: weeks)
        VStack(alignment: .leading, spacing: 6) {
            Text("Letzte \(weeks) Wochen")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 3) {
                ForEach(columns.indices, id: \.self) { week in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { weekday in
                            cellView(columns[week][weekday])
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(_ day: Day?) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        if let day {
            let ratio = streaks.completionRatio(on: day)
            shape
                .fill(color(for: ratio))
                .overlay(shape.strokeBorder(day == today ? Color.primary.opacity(0.6) : .clear, lineWidth: 1))
                .frame(width: cell, height: cell)
                .help(tooltip(day: day, ratio: ratio))
        } else {
            Color.clear.frame(width: cell, height: cell)
        }
    }

    private func color(for ratio: Double?) -> Color {
        guard let ratio, ratio > 0 else { return Color.primary.opacity(0.08) }
        return Color.green.opacity(0.25 + 0.75 * ratio)
    }

    private func tooltip(day: Day, ratio: Double?) -> String {
        let date = day.date().formatted(date: .abbreviated, time: .omitted)
        guard let ratio else { return date }
        return "\(date): \(Int((ratio * 100).rounded())) %"
    }
}

struct BreakFooter: View {
    let breaksToday: Int
    let breakStreak: Int
    let tracker: ActiveTimeTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("\(breaksToday) Bewegungspause\(breaksToday == 1 ? "" : "n") heute", systemImage: "figure.run")
                Spacer()
                if breakStreak > 0 {
                    Text("\(breakStreak) Tage in Folge")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            ProgressView(value: tracker.progress)
                .tint(tracker.progress > 0.85 ? Color.orange : Color.accentColor)
            Text("Nächste Pause in \(Int((tracker.remainingSeconds / 60).rounded(.up))) Min. aktiver Zeit")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
