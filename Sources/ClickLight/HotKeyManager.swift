import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    private static let hotKeySignature: OSType = 0x434C4854 // 'CLHT'

    private struct RegisteredHotKey {
        let reference: EventHotKeyRef
        let action: ClickShortcutAction
    }

    private var eventHandlerRef: EventHandlerRef?
    private var registeredHotKeys: [UInt32: RegisteredHotKey] = [:]
    private var onTrigger: (@MainActor @Sendable (ClickShortcutAction) -> Void)?

    init() {
        installEventHandlerIfNeeded()
    }

    deinit {
        unregisterAll()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    @discardableResult
    func registerShortcuts(
        _ shortcuts: [ClickShortcutAction: HotKeyBinding],
        onTrigger: @escaping @MainActor @Sendable (ClickShortcutAction) -> Void
    ) -> [ClickShortcutAction: String] {
        self.onTrigger = onTrigger
        unregisterAll()

        var seenBindings: [HotKeyBinding: ClickShortcutAction] = [:]
        var issues: [ClickShortcutAction: String] = [:]

        for action in ClickShortcutAction.allCases {
            guard let binding = shortcuts[action] else { continue }

            if let existingAction = seenBindings[binding] {
                let message = "Matches \(existingAction.title). Choose a unique shortcut."
                issues[action] = message
                NSLog("ClickLight: Duplicate shortcut for \(action.rawValue) was ignored.")
                continue
            }

            seenBindings[binding] = action
            if let status = register(action: action, binding: binding) {
                issues[action] = "Could not register globally (status \(status))."
            }
        }

        return issues
    }

    func unregisterAll() {
        let refs = registeredHotKeys.values.map(\.reference)
        registeredHotKeys.removeAll()

        for ref in refs {
            UnregisterEventHotKey(ref)
        }
    }

    private func register(action: ClickShortcutAction, binding: HotKeyBinding) -> OSStatus? {
        let eventID = action.hotKeyEventID

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: eventID)

        let status = RegisterEventHotKey(
            UInt32(binding.keyCode),
            UInt32(binding.carbonModifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            NSLog("ClickLight: Failed to register shortcut for \(action.rawValue) with status \(status).")
            return status
        }

        registeredHotKeys[eventID] = RegisteredHotKey(reference: hotKeyRef, action: action)
        return nil
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            Self.handleHotKeyEvent,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )
    }

    private func handleHotKey(id: UInt32) {
        guard let action = registeredHotKeys[id]?.action, let onTrigger else { return }
        // Carbon delivers hot-key events on the main thread; invoke synchronously
        // so the toggle happens even while the status menu's modal tracking loop
        // is running (DispatchQueue.main.async would defer until the menu closes).
        MainActor.assumeIsolated {
            onTrigger(action)
        }
    }

    private static let handleHotKeyEvent: EventHandlerUPP = { _, eventRef, userData in
        guard let eventRef, let userData else { return OSStatus(eventNotHandledErr) }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr, hotKeyID.signature == HotKeyManager.hotKeySignature else {
            return OSStatus(eventNotHandledErr)
        }

        let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotKey(id: hotKeyID.id)
        return noErr
    }
}
