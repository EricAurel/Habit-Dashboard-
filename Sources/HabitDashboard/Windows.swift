import AppKit
import SwiftUI

/// Randloses Panel, das auf Desktop-Ebene liegt: hinter allen App-Fenstern,
/// über den Schreibtisch-Symbolen, auf allen Spaces sichtbar und per Drag verschiebbar.
final class DesktopPanel: NSPanel {
    convenience init<Content: View>(rootView: Content) {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 440),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false

        let hosting = NSHostingController(rootView: rootView)
        hosting.sizingOptions = [.preferredContentSize]
        contentViewController = hosting

        if !setFrameUsingName(Self.autosaveName) {
            placeTopRight()
        }
        setFrameAutosaveName(Self.autosaveName)
    }

    static let autosaveName = "HabitDesktopPanel"

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    private func placeTopRight() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = frame.size
        setFrameOrigin(NSPoint(x: visible.maxX - size.width - 24, y: visible.maxY - size.height - 24))
    }
}

/// Normales Fenster für Popup und Editor, das die App beim Öffnen nach vorn holt.
@MainActor
final class FloatingWindowController {
    private var window: NSWindow?

    func show<Content: View>(title: String, floating: Bool, @ViewBuilder content: () -> Content) {
        if let window {
            window.contentViewController = NSHostingController(rootView: content())
            bringToFront(window)
            return
        }
        let hosting = NSHostingController(rootView: content())
        let window = NSWindow(contentViewController: hosting)
        window.title = title
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.level = floating ? .floating : .normal
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.center()
        self.window = window
        bringToFront(window)
    }

    func close() {
        window?.close()
        window = nil
    }

    var isVisible: Bool { window?.isVisible ?? false }

    private func bringToFront(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
