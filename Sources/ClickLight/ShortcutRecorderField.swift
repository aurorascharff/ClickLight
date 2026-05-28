import AppKit
import Carbon.HIToolbox
import SwiftUI

extension Notification.Name {
    static let shortcutRecordingDidBegin = Notification.Name("ClickLightShortcutRecordingDidBegin")
    static let shortcutRecordingDidEnd = Notification.Name("ClickLightShortcutRecordingDidEnd")
}

struct ShortcutRecorderField: View {
    let label: String
    let currentBinding: HotKeyBinding?
    let defaultBinding: HotKeyBinding?
    let errorMessage: String?
    let onRecord: (HotKeyBinding) -> Bool
    let onReset: () -> Void
    let onClear: () -> Void

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    private var isCustom: Bool {
        currentBinding != defaultBinding
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .font(.callout.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isRecording {
                    Text("Press shortcut...")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 112, alignment: .trailing)
                        .accessibilityLabel("Waiting for shortcut input")

                    Button("Cancel") {
                        stopRecording()
                    }
                    .buttonStyle(.bordered)
                    .help("Cancel shortcut recording.")
                } else {
                    Text(currentBinding?.displayString ?? "None")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(currentBinding == nil ? .secondary : .primary)
                        .frame(width: 112, alignment: .trailing)
                        .lineLimit(1)
                        .accessibilityLabel(currentBinding.map { "Current shortcut: \($0.descriptiveString)" } ?? "No shortcut assigned")
                        .help(currentBinding?.descriptiveString ?? "No shortcut configured.")

                    Button("Record") {
                        startRecording()
                    }
                    .buttonStyle(.bordered)
                    .help("Record a new shortcut.")

                    if currentBinding != nil {
                        Button("Clear") {
                            onClear()
                        }
                        .buttonStyle(.bordered)
                        .help("Remove this shortcut.")
                    }

                    if isCustom, defaultBinding != nil {
                        Button("Reset") {
                            onReset()
                        }
                        .buttonStyle(.bordered)
                        .help("Reset this shortcut to default.")
                    }
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .accessibilityLabel(errorMessage)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        NotificationCenter.default.post(name: .shortcutRecordingDidBegin, object: nil)

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            let code = Int(event.keyCode)

            if code == kVK_Escape {
                stopRecording()
                return nil
            }

            let modifierOnlyCodes: Set<Int> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
            guard !modifierOnlyCodes.contains(code) else {
                return event
            }

            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !flags.isEmpty else {
                NSSound.beep()
                stopRecording()
                return nil
            }

            let accepted = onRecord(HotKeyBinding(
                keyCode: code,
                carbonModifiers: HotKeyBinding.carbonModifiers(from: flags)
            ))
            if !accepted {
                NSSound.beep()
            }
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        guard isRecording || eventMonitor != nil else { return }
        isRecording = false
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        NotificationCenter.default.post(name: .shortcutRecordingDidEnd, object: nil)
    }
}
