import AppKit
import CoreAudio
import CoreMediaIO

/// Grund, warum gerade keine Bewegungs-Popups erscheinen sollen.
enum QuietReason: Equatable {
    case fullscreen
    case call

    var waitingText: String {
        switch self {
        case .fullscreen: return "wartet, bis du den Vollbildmodus verlässt"
        case .call: return "wartet, bis dein Call vorbei ist"
        }
    }
}

/// Erkennt Vollbild-Apps sowie aktive Mikrofone/Kameras.
/// Alle Abfragen funktionieren ohne zusätzliche Berechtigungen.
enum QuietTime {
    static func current(fullscreen checkFullscreen: Bool, calls checkCalls: Bool) -> QuietReason? {
        if checkCalls && (isMicrophoneInUse() || isCameraInUse()) { return .call }
        if checkFullscreen && isFullscreenAppActive() { return .fullscreen }
        return nil
    }

    // MARK: - Vollbild

    /// `true`, wenn die vorderste App ein Fenster in Bildschirmgröße zeigt
    /// (echter Vollbildmodus, Präsentationen, Videos im Vollbild, Spiele).
    static func isFullscreenAppActive() -> Bool {
        guard let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              front.bundleIdentifier != "com.apple.finder"
        else { return false }

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        let screenSizes = NSScreen.screens.map(\.frame.size)

        for info in windows {
            guard let pid = info[kCGWindowOwnerPID as String] as? NSNumber,
                  pid.int32Value == front.processIdentifier,
                  let layer = info[kCGWindowLayer as String] as? NSNumber,
                  layer.intValue == 0,
                  let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { continue }

            let coversScreen = screenSizes.contains {
                abs($0.width - bounds.width) < 1 && abs($0.height - bounds.height) < 1
            }
            if coversScreen { return true }
        }
        return false
    }

    // MARK: - Mikrofon

    /// `true`, wenn irgendein Eingabegerät (Mikrofon) gerade von einer App benutzt wird.
    static func isMicrophoneInUse() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr, size > 0 else { return false }
        var devices = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &devices) == noErr else { return false }

        return devices.contains { hasInputStreams($0) && isRunningSomewhere($0) }
    }

    private static func hasInputStreams(_ device: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr && size > 0
    }

    private static func isRunningSomewhere(_ device: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &running) == noErr else { return false }
        return running != 0
    }

    // MARK: - Kamera

    /// `true`, wenn irgendeine Kamera gerade von einer App benutzt wird.
    static func isCameraInUse() -> Bool {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr, size > 0 else { return false }
        var devices = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, size, &used, &devices) == noErr else { return false }

        for device in devices {
            var runningAddress = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
            )
            var running: UInt32 = 0
            var runningUsed: UInt32 = 0
            let status = CMIOObjectGetPropertyData(
                device, &runningAddress, 0, nil,
                UInt32(MemoryLayout<UInt32>.size), &runningUsed, &running
            )
            if status == noErr && running != 0 { return true }
        }
        return false
    }
}
