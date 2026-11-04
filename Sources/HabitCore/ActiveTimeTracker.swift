import Foundation

/// Zählt aktive Zeit am Rechner und meldet, wann eine Bewegungspause fällig ist.
///
/// Die App ruft `tick` regelmäßig auf und übergibt, wie lange seit der letzten
/// Maus-/Tastatureingabe vergangen ist. Wer länger als `idleReset` nichts tut,
/// hat bereits Pause gemacht – der Zähler beginnt von vorn.
///
/// Ist eine Pause fällig, während eine Ruhezeit gilt (Vollbild, Video-Call),
/// bleibt sie *vorgemerkt* und wird gemeldet, sobald die Ruhezeit endet.
public struct ActiveTimeTracker: Sendable, Equatable {
    public private(set) var activeSeconds: TimeInterval = 0
    /// Pause ist fällig, wartet aber auf das Ende einer Ruhezeit.
    public private(set) var isPending = false
    public var interval: TimeInterval
    public var idleReset: TimeInterval

    public init(interval: TimeInterval, idleReset: TimeInterval) {
        self.interval = interval
        self.idleReset = idleReset
    }

    public var remainingSeconds: TimeInterval { max(0, interval - activeSeconds) }

    public var progress: Double {
        interval > 0 ? min(1, activeSeconds / interval) : 0
    }

    /// - Parameters:
    ///   - elapsed: Sekunden seit dem letzten Tick.
    ///   - idleSeconds: Sekunden seit der letzten Benutzereingabe.
    ///   - quiet: `true`, solange keine Popups erscheinen sollen.
    /// - Returns: `true`, wenn jetzt das Pausen-Popup gezeigt werden soll.
    public mutating func tick(elapsed: TimeInterval, idleSeconds: TimeInterval, quiet: Bool = false) -> Bool {
        // Lange Lücke zwischen zwei Ticks (z. B. Ruhezustand) oder lange inaktiv => Pause gemacht.
        if elapsed >= idleReset || idleSeconds >= idleReset {
            reset()
            return false
        }
        if !isPending {
            activeSeconds = min(interval, activeSeconds + elapsed)
            if activeSeconds >= interval {
                isPending = true
            }
        }
        if isPending && !quiet {
            reset()
            return true
        }
        return false
    }

    public mutating func reset() {
        activeSeconds = 0
        isPending = false
    }

    /// Erinnert in `seconds` aktiver Zeit erneut.
    public mutating func snooze(seconds: TimeInterval) {
        isPending = false
        activeSeconds = max(0, interval - seconds)
    }
}
