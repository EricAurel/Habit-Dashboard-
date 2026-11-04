import AppKit
import Combine
import HabitCore
import SwiftUI

@main
struct HabitDashboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: appDelegate)
                .environmentObject(appDelegate.state)
        } label: {
            Image(systemName: "checkmark.circle.fill")
        }
    }
}

/// Einträge im Menüleisten-Menü.
struct MenuContent: View {
    @EnvironmentObject var state: AppState
    let controller: AppDelegate

    var body: some View {
        let streak = state.streaks.overallStreak(today: state.today)
        Text("🔥 \(streak) Tage Gesamt-Streak")
        Text("Nächste Bewegungspause in \(Int((state.tracker.remainingSeconds / 60).rounded(.up))) Min.")
        Divider()
        Button("Jetzt Bewegungspause machen") { controller.showExercisePrompt() }
        Button(state.settings.showDesktopWidget ? "Widget ausblenden" : "Widget anzeigen") {
            state.updateSettings { $0.showDesktopWidget.toggle() }
        }
        Button("Statistik …") { controller.showStats() }
        Button("Gewohnheiten & Einstellungen …") { controller.showEditor() }
            .keyboardShortcut(",")
        Divider()
        Button("Beenden") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private let monitor = ActivityMonitor()
    private var desktopPanel: DesktopPanel?
    private let promptWindow = FloatingWindowController()
    private let editorWindow = FloatingWindowController()
    private let statsWindow = FloatingWindowController()
    private var settingsObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Kein Dock-Symbol – auch beim Start per `swift run`.
        NSApp.setActivationPolicy(.accessory)

        let panel = DesktopPanel(
            rootView: DesktopWidgetView(
                onEdit: { [weak self] in self?.showEditor() },
                onStats: { [weak self] in self?.showStats() }
            )
                .environmentObject(state)
        )
        desktopPanel = panel
        updatePanelVisibility()

        settingsObserver = state.$data
            .map(\.settings.showDesktopWidget)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.updatePanelVisibility() }
            }

        monitor.onTick = { [weak self] elapsed, idle in
            guard let self else { return }
            // Während das Popup offen ist, wird nicht weitergezählt.
            guard !self.promptWindow.isVisible else { return }
            let settings = self.state.settings
            let quiet = QuietTime.current(
                fullscreen: settings.quietDuringFullscreen,
                calls: settings.quietDuringCalls
            )
            if self.state.tick(elapsed: elapsed, idleSeconds: idle, quiet: quiet) {
                self.showExercisePrompt()
            }
        }
        monitor.onBreakDetected = { [weak self] in
            self?.state.resetActiveTime()
        }
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private func updatePanelVisibility() {
        if state.settings.showDesktopWidget {
            desktopPanel?.orderFront(nil)
        } else {
            desktopPanel?.orderOut(nil)
        }
    }

    func showExercisePrompt() {
        let count = state.settings.exercisesPerBreak
        promptWindow.show(title: "Bewegungspause", floating: true) {
            ExercisePromptView(
                exercises: ExerciseCatalog.random(count: count),
                count: count,
                snoozeMinutes: state.settings.snoozeMinutes,
                breakStreak: state.streaks.breakStreak(today: state.today),
                onDone: { [weak self] entries in
                    self?.state.logBreak(entries: entries)
                    self?.closePrompt()
                },
                onSnooze: { [weak self] in
                    self?.state.snooze()
                    self?.closePrompt()
                },
                onSkip: { [weak self] in
                    self?.state.resetActiveTime()
                    self?.closePrompt()
                }
            )
        }
    }

    private func closePrompt() {
        promptWindow.close()
        monitor.restartClock()
    }

    func showStats() {
        statsWindow.show(title: "Statistik", floating: false) {
            StatsView().environmentObject(state)
        }
    }

    func showEditor() {
        editorWindow.show(title: "Habit Dashboard", floating: false) {
            HabitEditorView().environmentObject(state)
        }
    }
}
