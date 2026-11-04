import AppKit
import CoreGraphics

/// Prüft regelmäßig, wie lange die letzte Maus-/Tastatureingabe her ist,
/// und meldet Ruhezustand / Bildschirmsperre als Pause.
@MainActor
final class ActivityMonitor {
    /// (Sekunden seit letztem Tick, Sekunden seit letzter Eingabe)
    var onTick: ((TimeInterval, TimeInterval) -> Void)?
    var onBreakDetected: (() -> Void)?

    private var timer: Timer?
    private var lastTick = Date()
    private var observers: [NSObjectProtocol] = []
    private let tickInterval: TimeInterval = 15

    func start() {
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.fire() }
        }
        timer?.tolerance = 2

        let center = NSWorkspace.shared.notificationCenter
        let pauseEvents: [Notification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification,
        ]
        for name in pauseEvents {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.onBreakDetected?() }
            })
        }
        // Nach dem Aufwachen nicht die Schlafzeit als aktive Zeit zählen.
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.lastTick = Date() }
        })
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        observers.removeAll()
    }

    /// Ignoriert den Zeitraum, in dem z. B. das Übungs-Popup offen war.
    func restartClock() {
        lastTick = Date()
    }

    private func fire() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTick)
        lastTick = now
        onTick?(elapsed, Self.secondsSinceLastInput())
    }

    static func secondsSinceLastInput() -> TimeInterval {
        // kCGAnyInputEventType (~0) = jede Art von Eingabe.
        guard let anyInput = CGEventType(rawValue: ~0) else { return 0 }
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }
}
