import AppKit
import Carbon.HIToolbox

struct HotKeyBinding: Equatable, Hashable {
    let keyCode: Int
    let carbonModifiers: Int

    static let defaultToggleModifiers: Int = Int(controlKey | optionKey | cmdKey)

    var displayString: String {
        modifiersString + keyString
    }

    var modifiersString: String {
        var value = ""
        if carbonModifiers & Int(controlKey) != 0 { value += "⌃" }
        if carbonModifiers & Int(optionKey) != 0 { value += "⌥" }
        if carbonModifiers & Int(shiftKey) != 0 { value += "⇧" }
        if carbonModifiers & Int(cmdKey) != 0 { value += "⌘" }
        return value
    }

    var keyString: String {
        Self.keyCodeToDisplayString(keyCode) ?? "?"
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var mods = 0
        if flags.contains(.command) { mods |= Int(cmdKey) }
        if flags.contains(.shift) { mods |= Int(shiftKey) }
        if flags.contains(.option) { mods |= Int(optionKey) }
        if flags.contains(.control) { mods |= Int(controlKey) }
        return mods
    }

    static func keyCodeToDisplayString(_ code: Int) -> String? {
        guard let rawSource = TISCopyCurrentKeyboardLayoutInputSource() else {
            return fallbackKeyCodeString(code)
        }

        let source = rawSource.takeRetainedValue()
        guard let dataPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return fallbackKeyCodeString(code)
        }

        let layoutData = Unmanaged<CFData>.fromOpaque(dataPtr).takeUnretainedValue()
        guard let bytePtr = CFDataGetBytePtr(layoutData) else {
            return fallbackKeyCodeString(code)
        }

        return bytePtr.withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { layout in
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var length = 0

            let result = UCKeyTranslate(
                layout,
                UInt16(code),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysMask),
                &deadKeyState,
                4,
                &length,
                &chars
            )

            guard result == noErr, length > 0 else {
                return fallbackKeyCodeString(code)
            }

            return String(utf16CodeUnits: Array(chars.prefix(length)), count: length).uppercased()
        }
    }

    private static func fallbackKeyCodeString(_ code: Int) -> String? {
        switch code {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "Esc"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return nil
        }
    }
}

enum ClickShortcutAction: String, CaseIterable, Identifiable {
    case toggleEnabled
    case toggleLaserPointer
    case toggleShowPress
    case toggleShowRelease
    case toggleShowRightClick
    case toggleShowMiddleClick
    case toggleShowDrag

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toggleEnabled:
            return "Toggle ClickLight"
        case .toggleLaserPointer:
            return "Toggle Laser Pointer"
        case .toggleShowPress:
            return "Toggle Show Press"
        case .toggleShowRelease:
            return "Toggle Show Release"
        case .toggleShowRightClick:
            return "Toggle Show Right Click"
        case .toggleShowMiddleClick:
            return "Toggle Show Middle Click"
        case .toggleShowDrag:
            return "Toggle Show Drag"
        }
    }

    var subtitle: String {
        switch self {
        case .toggleEnabled:
            return "Enable or disable all click highlighting."
        case .toggleLaserPointer:
            return "Turn laser pointer mode on or off."
        case .toggleShowPress:
            return "Show or hide mouse-down highlights."
        case .toggleShowRelease:
            return "Show or hide mouse-up highlights."
        case .toggleShowRightClick:
            return "Show or hide right-click highlights."
        case .toggleShowMiddleClick:
            return "Show or hide middle-click highlights."
        case .toggleShowDrag:
            return "Show or hide drag trails."
        }
    }

    var hotKeyEventID: UInt32 {
        switch self {
        case .toggleEnabled:
            return 1
        case .toggleLaserPointer:
            return 2
        case .toggleShowPress:
            return 3
        case .toggleShowRelease:
            return 4
        case .toggleShowRightClick:
            return 5
        case .toggleShowMiddleClick:
            return 6
        case .toggleShowDrag:
            return 7
        }
    }

    var defaultBinding: HotKeyBinding {
        switch self {
        case .toggleEnabled:
            return HotKeyBinding(keyCode: kVK_ANSI_1, carbonModifiers: HotKeyBinding.defaultToggleModifiers)
        case .toggleLaserPointer:
            return HotKeyBinding(keyCode: kVK_ANSI_2, carbonModifiers: HotKeyBinding.defaultToggleModifiers)
        case .toggleShowPress:
            return HotKeyBinding(keyCode: kVK_ANSI_3, carbonModifiers: HotKeyBinding.defaultToggleModifiers)
        case .toggleShowRelease:
            return HotKeyBinding(keyCode: kVK_ANSI_4, carbonModifiers: HotKeyBinding.defaultToggleModifiers)
        case .toggleShowRightClick:
            return HotKeyBinding(keyCode: kVK_ANSI_5, carbonModifiers: HotKeyBinding.defaultToggleModifiers)
        case .toggleShowMiddleClick:
            return HotKeyBinding(keyCode: kVK_ANSI_6, carbonModifiers: HotKeyBinding.defaultToggleModifiers)
        case .toggleShowDrag:
            return HotKeyBinding(keyCode: kVK_ANSI_7, carbonModifiers: HotKeyBinding.defaultToggleModifiers)
        }
    }
}
