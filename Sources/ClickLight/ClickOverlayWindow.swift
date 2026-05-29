import AppKit

final class ClickOverlayWindow: NSWindow {
    private let overlayView: ClickOverlayView

    init(screen: NSScreen, settings: ClickSettings) {
        overlayView = ClickOverlayView(screenFrame: screen.frame, settings: settings)
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        contentView = overlayView
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = false
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary
        ]
        level = .screenSaver
        isReleasedWhenClosed = false
    }

    func apply(settings: ClickSettings) {
        overlayView.apply(settings: settings)
    }

    func show(event: ClickEvent, settings: ClickSettings) {
        orderFrontRegardless()
        overlayView.show(event: event, settings: settings)
    }

    func show(shortcut: KeyboardShortcutEvent, settings: ClickSettings) {
        orderFrontRegardless()
        overlayView.show(shortcut: shortcut, settings: settings)
    }
}
