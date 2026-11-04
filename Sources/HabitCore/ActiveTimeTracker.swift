import Foundation

/// Zählt aktive Zeit am Rechner und meldet, wann eine Bewegungspause fällig ist.
///
/// Die App ruft `tick` regelmäßig auf und übergibt, wie lange seit der letzten
/// Maus-/Tastatureingabe vergangen ist. Wer länger als `idleReset` nichts tut,
/// hat bereits Pause gemacht – der Zähler beginnt von vorn.
public struct ActiveTimeTracker: Sendable, Equatable {
    public private(set) var activeSeconds: TimeInterval = 0
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
    /// - Returns: `true`, wenn jetzt eine Bewegungspause fällig ist.
    public mutating func tick(elapsed: TimeInterval, idleSeconds: TimeInterval) -> Bool {
        // Lange Lücke zwischen zwei Ticks (z. B. Ruhezustand) oder lange inaktiv => Pause gemacht.
        if elapsed >= idleReset || idleSeconds >= idleReset {
            activeSeconds = 0
            return false
        }
        activeSeconds += elapsed
        if activeSeconds >= interval {
            activeSeconds = 0
            return true
        }
        return false
    }

    public mutating func reset() {
        activeSeconds = 0
    }

    /// Erinnert in `seconds` aktiver Zeit erneut.
    public mutating func snooze(seconds: TimeInterval) {
        activeSeconds = max(0, interval - seconds)
    }
}
