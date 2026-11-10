import HabitCore
import SwiftUI

/// Das Widget auf dem Schreibtisch.
struct DesktopWidgetView: View {
    @EnvironmentObject var state: AppState
    var onEdit: () -> Void = {}
    var onStats: () -> Void = {}
    /// Startet eine Bewegungspause; nil = Anzahl Übungen aus den Einstellungen.
    var onBreak: (Int?) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        let streaks = state.streaks
        let habits = state.data.habits
        let doneCount = habits.filter { state.isDone($0) }.count
        let collapsed = state.settings.widgetCollapsed

        VStack(alignment: .leading, spacing: 14) {
            toolbar(collapsed: collapsed)
            header(streak: streaks.overallStreak(today: state.today), done: doneCount, total: habits.count)

            if !collapsed {
                content(habits: habits, streaks: streaks)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12))
        )
        .contextMenu {
            Button("Bewegungspause starten") { onBreak(nil) }
            Button("Statistik …", action: onStats)
            Button("Gewohnheiten bearbeiten …", action: onEdit)
            Divider()
            Button(collapsed ? "Ausklappen" : "Einklappen", action: toggleCollapsed)
            Button("Widget schließen", action: onClose)
        }
    }

    // MARK: - Leiste oben

    private func toolbar(collapsed: Bool) -> some View {
        let defaultCount = state.settings.exercisesPerBreak
        return HStack(spacing: 12) {
            Menu {
                Button("Jetzt starten (\(defaultCount) Übung\(defaultCount == 1 ? "" : "en"))") { onBreak(nil) }
                Divider()
                Button("Kurz – 1 Übung") { onBreak(1) }
                Button("Normal – 3 Übungen") { onBreak(3) }
                Button("Ausgiebig – 5 Übungen") { onBreak(5) }
            } label: {
                Label("Bewegungspause", systemImage: "figure.run")
                    .font(.caption.weight(.semibold))
            } primaryAction: {
                onBreak(nil)
            }
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .fixedSize()
            .help("Klick: Pause jetzt starten · Pfeil: Länge wählen")

            Spacer()

            ToolbarIcon(systemName: "chart.bar.xaxis", help: "Statistik öffnen", action: onStats)
            ToolbarIcon(
                systemName: collapsed ? "chevron.down" : "chevron.up",
                help: collapsed ? "Widget ausklappen" : "Widget einklappen",
                action: toggleCollapsed
            )
            ToolbarIcon(
                systemName: "xmark",
                help: "Widget schließen – über 👍 in der Menüleiste wieder öffnen",
                action: onClose
            )
        }
    }

    private func toggleCollapsed() {
        withAnimation(.easeInOut(duration: 0.2)) {
            state.updateSettings { $0.widgetCollapsed.toggle() }
        }
    }

    // MARK: - Inhalt

    @ViewBuilder
    private func content(habits: [Habit], streaks: StreakCalculator) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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

            HeatmapView(streaks: streaks, today: state.today, selected: state.viewedDay) { day in
                withAnimation(.easeInOut(duration: 0.15)) { state.show(day) }
            }

            BreakFooter(
                breaksToday: state.data.breaks(on: state.today),
                breakStreak: streaks.breakStreak(today: state.today),
                tracker: state.tracker,
                quietReason: state.quietReason
            )
        }
    }

    private func header(streak: Int, done: Int, total: Int) -> some View {
        let viewingToday = state.isViewingToday
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ToolbarIcon(systemName: "chevron.left", help: "Vorheriger Tag – vergessene Gewohnheiten nachtragen") {
                        withAnimation(.easeInOut(duration: 0.15)) { state.showPreviousDay() }
                    }
                    .disabled(!state.canGoBack)
                    Text(dayTitle(state.viewedDay))
                        .font(.headline)
                        .lineLimit(1)
                        .contentTransition(.opacity)
                    ToolbarIcon(systemName: "chevron.right", help: "Nächster Tag") {
                        withAnimation(.easeInOut(duration: 0.15)) { state.showNextDay() }
                    }
                    .disabled(viewingToday)
                }
                if !viewingToday {
                    HStack(spacing: 6) {
                        Text("Nachtragen")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.25)))
                        Button("Zurück zu heute") {
                            withAnimation(.easeInOut(duration: 0.15)) { state.showToday() }
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
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

    /// "Heute, Di. 10. Nov.", "Gestern, Mo. 9. Nov." oder "Do. 5. Nov."
    private func dayTitle(_ day: Day) -> String {
        let date = day.date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        if day == state.today { return "Heute, \(date)" }
        if day == state.today.adding(days: -1) { return "Gestern, \(date)" }
        return date
    }
}

struct ToolbarIcon: View {
    let systemName: String
    let help: String
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(hovering ? Color.primary : Color.secondary)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.primary.opacity(hovering ? 0.1 : 0)))
                .contentShape(Circle())
                .opacity(isEnabled ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .onHover { hovering = isEnabled && $0 }
        .help(help)
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
                if let level = Milestones.reached(streak: streak) {
                    Text(Milestones.badge(for: level))
                        .font(.callout)
                        .help("\(level)-Tage-Meilenstein erreicht")
                }
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

/// Übersicht der letzten Wochen: jede Spalte eine Woche, jede Zeile ein Wochentag.
/// Je grüner ein Kästchen, desto mehr Gewohnheiten wurden an dem Tag erledigt.
/// Ein Klick auf einen Tag springt dorthin (zum Nachtragen).
struct HeatmapView: View {
    let streaks: StreakCalculator
    let today: Day
    let selected: Day
    var onSelect: (Day) -> Void = { _ in }

    private let weeks = 15
    private let cell: CGFloat = 12
    private let gap: CGFloat = 3
    private let labelWidth: CGFloat = 16
    private static let weekdayNames = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]

    var body: some View {
        let columns = HeatmapGrid.columns(endingAt: today, weeks: weeks)
        VStack(alignment: .leading, spacing: 6) {
            Text("Erledigt pro Tag · letzte \(weeks) Wochen")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 4) {
                // Wochentage links
                VStack(alignment: .trailing, spacing: gap) {
                    Color.clear.frame(width: labelWidth, height: 10)
                    ForEach(0..<7, id: \.self) { row in
                        Text(weekdayName(row))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: labelWidth, height: cell, alignment: .trailing)
                    }
                }

                HStack(alignment: .top, spacing: gap) {
                    ForEach(columns.indices, id: \.self) { week in
                        VStack(spacing: gap) {
                            monthLabel(columns: columns, week: week)
                            ForEach(0..<7, id: \.self) { row in
                                cellView(columns[week][row])
                            }
                        }
                    }
                }
            }

            legend
        }
    }

    // MARK: - Teile

    private func weekdayName(_ row: Int) -> String {
        let weekday = (Calendar.current.firstWeekday - 1 + row) % 7
        return Self.weekdayNames[weekday]
    }

    /// Monatsname über der ersten Woche eines neuen Monats.
    private func monthLabel(columns: [[Day?]], week: Int) -> some View {
        let first = columns[week].compactMap { $0 }.first
        let previous = week > 0 ? columns[week - 1].compactMap { $0 }.first : nil
        let isNewMonth = first != nil && (previous == nil || previous?.month != first?.month)
        return ZStack(alignment: .leading) {
            if isNewMonth, let first {
                Text(first.date().formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
        .frame(width: cell, height: 10, alignment: .leading)
    }

    @ViewBuilder
    private func cellView(_ day: Day?) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        if let day {
            let ratio = streaks.completionRatio(on: day)
            let isSelected = day == selected
            shape
                .fill(color(for: ratio))
                .overlay(
                    shape.strokeBorder(
                        isSelected ? Color.orange : (day == today ? Color.primary.opacity(0.6) : .clear),
                        lineWidth: isSelected ? 1.5 : 1
                    )
                )
                .frame(width: cell, height: cell)
                .contentShape(Rectangle())
                .onTapGesture { onSelect(day) }
                .help(tooltip(day: day, ratio: ratio))
        } else {
            Color.clear.frame(width: cell, height: cell)
        }
    }

    private var legend: some View {
        HStack(spacing: 3) {
            Text("Weniger")
            ForEach([0.0, 0.34, 0.67, 1.0], id: \.self) { ratio in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(for: ratio))
                    .frame(width: 9, height: 9)
            }
            Text("Mehr")
            Spacer()
            Text("Klick auf einen Tag = nachtragen")
        }
        .font(.system(size: 8))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .padding(.leading, labelWidth + 4)
    }

    private func color(for ratio: Double?) -> Color {
        guard let ratio, ratio > 0 else { return Color.primary.opacity(0.08) }
        return Color.green.opacity(0.25 + 0.75 * ratio)
    }

    private func tooltip(day: Day, ratio: Double?) -> String {
        let date = day.date().formatted(.dateTime.weekday(.wide).day().month(.wide))
        guard let ratio else { return "\(date): keine Gewohnheiten" }
        return "\(date): \(Int((ratio * 100).rounded())) % erledigt"
    }
}

struct BreakFooter: View {
    let breaksToday: Int
    let breakStreak: Int
    let tracker: ActiveTimeTracker
    let quietReason: QuietReason?

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
            ProgressView(value: tracker.isPending ? 1 : tracker.progress)
                .tint(tracker.progress > 0.85 ? Color.orange : Color.accentColor)
            Group {
                if tracker.isPending, let quietReason {
                    Text("Pause fällig – \(quietReason.waitingText)")
                } else {
                    Text("Nächste Pause in \(Int((tracker.remainingSeconds / 60).rounded(.up))) Min. aktiver Zeit")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
