import HabitCore
import ServiceManagement
import SwiftUI

/// Gewohnheiten verwalten und Einstellungen ändern.
struct HabitEditorView: View {
    @EnvironmentObject var state: AppState
    @State private var newEmoji = "✅"
    @State private var newName = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Gewohnheiten") {
                List {
                    ForEach(state.data.habits) { habit in
                        HabitEditRow(habit: habit)
                    }
                    .onMove { state.moveHabits(from: $0, to: $1) }
                }
                .frame(minHeight: 160)

                HStack {
                    EmojiPicker(selection: $newEmoji)
                    TextField("Neue Gewohnheit", text: $newName)
                        .onSubmit(add)
                    Button("Hinzufügen", action: add)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Text("Tipp: Emoji über das Menü links wählen. Reihenfolge per Drag & Drop.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Bewegungspausen") {
                Stepper(
                    "Erinnern nach \(state.settings.breakIntervalMinutes) Min. aktiver Zeit",
                    value: settingBinding(\.breakIntervalMinutes),
                    in: 15...180,
                    step: 15
                )
                Stepper(
                    "Zähler zurücksetzen nach \(state.settings.idleResetMinutes) Min. Inaktivität",
                    value: settingBinding(\.idleResetMinutes),
                    in: 1...30
                )
                Stepper(
                    "Später erinnern: \(state.settings.snoozeMinutes) Min.",
                    value: settingBinding(\.snoozeMinutes),
                    in: 5...30,
                    step: 5
                )
                Stepper(
                    "\(state.settings.exercisesPerBreak) Übungen pro Pause",
                    value: settingBinding(\.exercisesPerBreak),
                    in: 1...5
                )
                Toggle("Nicht stören bei Vollbild-Apps", isOn: settingBinding(\.quietDuringFullscreen))
                Toggle("Nicht stören während Video-Calls (Mikrofon/Kamera aktiv)", isOn: settingBinding(\.quietDuringCalls))
                Text("Eine fällige Pause wird dann aufgehoben und erscheint, sobald du wieder frei bist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Allgemein") {
                Toggle("Widget auf dem Schreibtisch anzeigen", isOn: settingBinding(\.showDesktopWidget))
                Toggle("Beim Anmelden automatisch starten", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
                if let error = state.lastError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 620)
    }

    private func add() {
        state.addHabit(name: newName, emoji: newEmoji)
        newName = ""
        newEmoji = "✅"
    }

    private func settingBinding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { state.settings[keyPath: keyPath] },
            set: { value in state.updateSettings { $0[keyPath: keyPath] = value } }
        )
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = "Autostart funktioniert nur, wenn die App als .app-Bundle läuft (scripts/build-app.sh). \(error.localizedDescription)"
        }
    }
}

struct HabitEditRow: View {
    @EnvironmentObject var state: AppState
    let habit: Habit

    var body: some View {
        HStack {
            EmojiPicker(selection: Binding(
                get: { habit.emoji },
                set: { state.rename(habit, emoji: $0) }
            ))
            TextField("", text: Binding(
                get: { habit.name },
                set: { state.rename(habit, name: $0) }
            ))
            Text("🔥 \(state.streaks.currentStreak(for: habit.id, today: state.today)) · Rekord \(state.streaks.longestStreak(for: habit.id))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(role: .destructive) {
                state.removeHabit(habit)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Gewohnheit löschen (inkl. Verlauf)")
        }
    }
}
