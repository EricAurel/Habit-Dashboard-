import HabitCore
import SwiftUI

/// Popup nach einer Stunde aktiver Zeit. Für jede Übung lässt sich eintragen,
/// wie viele Wiederholungen bzw. Sekunden tatsächlich geschafft wurden.
struct ExercisePromptView: View {
    @State private var exercises: [Exercise]
    @State private var amounts: [String: Int]
    let count: Int
    let snoozeMinutes: Int
    let breakStreak: Int
    let onDone: ([ExerciseEntry]) -> Void
    let onSnooze: () -> Void
    let onSkip: () -> Void

    init(
        exercises: [Exercise],
        count: Int,
        snoozeMinutes: Int,
        breakStreak: Int,
        onDone: @escaping ([ExerciseEntry]) -> Void,
        onSnooze: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        _exercises = State(initialValue: exercises)
        _amounts = State(initialValue: Self.defaultAmounts(for: exercises))
        self.count = count
        self.snoozeMinutes = snoozeMinutes
        self.breakStreak = breakStreak
        self.onDone = onDone
        self.onSnooze = onSnooze
        self.onSkip = onSkip
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("🏃‍♂️").font(.system(size: 44))
                Text("Zeit für eine Bewegungspause!")
                    .font(.title2.bold())
                Text("Du warst eine Stunde aktiv am Rechner. Steh auf und trag ein, was du geschafft hast:")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                ForEach(exercises) { exercise in
                    ExerciseInputRow(exercise: exercise, amount: amountBinding(for: exercise))
                }
            }

            Button {
                withAnimation {
                    exercises = ExerciseCatalog.random(count: count)
                    amounts = Self.defaultAmounts(for: exercises)
                }
            } label: {
                Label("Andere Übungen", systemImage: "shuffle")
            }
            .buttonStyle(.link)

            HStack(spacing: 10) {
                Button("Überspringen", action: onSkip)
                    .keyboardShortcut(.cancelAction)
                Button("In \(snoozeMinutes) Min.", action: onSnooze)
                Button {
                    onDone(exercises.map { ExerciseEntry(exercise: $0, amount: amounts[$0.id] ?? 0) })
                } label: {
                    Text(breakStreak > 0 ? "Erledigt 💪 (\(breakStreak + 1). Tag)" : "Erledigt 💪")
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 440)
    }

    private func amountBinding(for exercise: Exercise) -> Binding<Int> {
        Binding(
            get: { amounts[exercise.id] ?? exercise.target },
            set: { amounts[exercise.id] = max(0, $0) }
        )
    }

    private static func defaultAmounts(for exercises: [Exercise]) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0.target) })
    }
}

struct ExerciseInputRow: View {
    let exercise: Exercise
    @Binding var amount: Int

    private var step: Int { exercise.unit == .seconds ? 5 : 1 }

    var body: some View {
        HStack(spacing: 12) {
            Text(exercise.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(.body.weight(.medium))
                Text("Ziel: \(exercise.amount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            TextField("0", value: $amount, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
            Text(exercise.unit.short)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
            Stepper("", value: $amount, in: 0...999, step: step)
                .labelsHidden()
            Image(systemName: amount >= exercise.target ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(amount >= exercise.target ? Color.green : Color.secondary)
                .help(amount >= exercise.target ? "Ziel erreicht" : "Unter dem Ziel")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
