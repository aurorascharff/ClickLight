import AppKit
import ApplicationServices

@MainActor
final class PermissionController {
    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    var isInputMonitoringTrusted: Bool {
        CGPreflightListenEventAccess()
    }

    func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func requestInputMonitoringIfNeeded() {
        guard !CGPreflightListenEventAccess() else { return }
        CGRequestListenEventAccess()
    }

    func openPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    func openInputMonitoringSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }
}
