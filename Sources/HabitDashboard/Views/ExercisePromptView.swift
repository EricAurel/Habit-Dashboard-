import HabitCore
import SwiftUI

/// Popup nach einer Stunde aktiver Zeit.
struct ExercisePromptView: View {
    @State var exercises: [Exercise]
    let count: Int
    let snoozeMinutes: Int
    let breakStreak: Int
    let onDone: () -> Void
    let onSnooze: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("🏃‍♂️").font(.system(size: 44))
                Text("Zeit für eine Bewegungspause!")
                    .font(.title2.bold())
                Text("Du sitzt seit einer Stunde am Rechner. Steh kurz auf:")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                ForEach(exercises) { exercise in
                    HStack(spacing: 12) {
                        Text(exercise.emoji).font(.title2)
                        Text(exercise.name).font(.body.weight(.medium))
                        Spacer()
                        Text(exercise.amount)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            Button {
                withAnimation { exercises = ExerciseCatalog.random(count: count) }
            } label: {
                Label("Andere Übungen", systemImage: "shuffle")
            }
            .buttonStyle(.link)

            HStack(spacing: 10) {
                Button("Überspringen", action: onSkip)
                    .keyboardShortcut(.cancelAction)
                Button("In \(snoozeMinutes) Min.", action: onSnooze)
                Button(action: onDone) {
                    Text(breakStreak > 0 ? "Erledigt 💪 (\(breakStreak + 1). Tag)" : "Erledigt 💪")
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 400)
    }
}
