import AppKit
import SwiftUI

struct ClickLightSettingsView: View {
    @ObservedObject var viewModel: ClickLightSettingsViewModel
    @State private var selectedPane: SettingsPane = .general
    @State private var showResetConfirmation = false
    @State private var showShortcutResetConfirmation = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(SettingsPane.allCases, id: \.self, selection: $selectedPane) { pane in
                    Label {
                        Text(pane.title)
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        Image(systemName: pane.icon)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 2)
                    .tag(pane)
                }
                .listStyle(.sidebar)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Preview Pad", systemImage: "cursorarrow.click.2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ClickPreviewPad(settings: viewModel.settings)
                        .frame(height: 116)
                        .accessibilityLabel("Preview Pad")
                }
                .padding(12)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    paneHeader

                    Group {
                        switch selectedPane {
                        case .general:
                            generalPane
                        case .style:
                            stylePane
                        case .shortcuts:
                            shortcutsPane
                        case .events:
                            eventsPane
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.never)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func customColorRow(title: String, subtitle: String, color: Binding<Color>) -> some View {
        ModernRow(title: title, subtitle: subtitle) {
            ColorPicker(
                "",
                selection: color,
                supportsOpacity: false
            )
            .labelsHidden()
            .accessibilityLabel(title)
        }
    }

    private func customClickColorBinding(_ target: CustomClickColorTarget) -> Binding<Color> {
        Binding(
            get: {
                switch target {
                case .left:
                    return Color(nsColor: viewModel.settings.customLeftColor)
                case .right:
                    return Color(nsColor: viewModel.settings.customRightColor)
                case .middle:
                    return Color(nsColor: viewModel.settings.customMiddleColor)
                case .drag:
                    return Color(nsColor: viewModel.settings.customDragColor)
                }
            },
            set: { viewModel.applyCustomColor(NSColor($0), to: target) }
        )
    }

    // MARK: - Pane Header

    private var paneHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedPane.title)
                .font(.system(size: 22, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            Text(selectedPane.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Panes

    private var generalPane: some View {
        VStack(spacing: 16) {
            SettingsCard {
                ModernRow(title: "Enable ClickLight",
                          subtitle: "Show pulse highlights on every click.") {
                    Toggle("", isOn: binding(\.isEnabled))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Enable ClickLight")
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    ModernRow(title: "Launch at Login",
                              subtitle: "Open ClickLight automatically after signing in.") {
                        Toggle("", isOn: Binding(
                            get: { viewModel.launchAtLoginEnabled },
                            set: { viewModel.setLaunchAtLogin($0) }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Launch at Login")
                    }
                    if let message = viewModel.launchAtLoginErrorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            SettingsCard {
                ModernRow(title: "Show Menu Bar Text",
                          subtitle: "Display the ClickLight name next to the menu bar icon.") {
                    Toggle("", isOn: binding(\.showMenuBarText))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Show Menu Bar Text")
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.accessibilityTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(viewModel.accessibilityTrusted ? .green : .orange)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.accessibilityTrusted ? "Accessibility Granted" : "Accessibility Required")
                                .font(.callout.weight(.medium))
                            Text(viewModel.accessibilityTrusted
                                 ? "ClickLight can observe clicks across the system."
                                 : "Grant Accessibility access so ClickLight can see your clicks.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    HStack {
                        Spacer()
                        Button {
                            viewModel.openAccessibilitySettings()
                        } label: {
                            Label(viewModel.accessibilityTrusted ? "Open Accessibility Settings" : "Grant Access…",
                                  systemImage: "arrow.up.right.square")
                        }
                        .controlSize(.regular)
                    }
                }
            }

            if viewModel.settings.showLiveKeyboardShortcuts {
                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: viewModel.inputMonitoringTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(viewModel.inputMonitoringTrusted ? .green : .orange)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.inputMonitoringTrusted ? "Input Monitoring Granted" : "Input Monitoring Required")
                                    .font(.callout.weight(.medium))
                                Text(viewModel.inputMonitoringTrusted
                                     ? "ClickLight can observe keyboard shortcuts across the system."
                                     : "Grant Input Monitoring access so ClickLight can show keyboard shortcuts.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        HStack {
                            Spacer()
                            Button {
                                viewModel.openInputMonitoringSettings()
                            } label: {
                                Label(viewModel.inputMonitoringTrusted ? "Open Input Monitoring Settings" : "Grant Access...",
                                      systemImage: "arrow.up.right.square")
                            }
                            .controlSize(.regular)
                        }
                    }
                }
            }

            SettingsCard {
                ModernRow(title: "Reset to Defaults",
                          subtitle: "Restore size, intensity, duration, color, and toggles.") {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .controlSize(.regular)
                }
            }

        }
        .confirmationDialog(
            "Reset all ClickLight settings?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                viewModel.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores size, intensity, duration, color, and visibility toggles to their defaults.")
        }
    }

    private var stylePane: some View {
        VStack(spacing: 16) {
            SettingsCard(title: "Size", subtitle: "How large the click pulse appears.") {
                VStack(alignment: .leading, spacing: 16) {
                    presetSegmented(
                        label: "Size Preset",
                        selection: Binding(
                            get: { viewModel.sizePresetSelection },
                            set: { viewModel.applySizePresetSelection($0) }
                        ),
                        options: ClickSettingOptions.sizePresets
                    )

                    modernSlider(
                        label: "Size",
                        value: Binding(
                            get: { Double(viewModel.settings.size) },
                            set: { newValue in
                                viewModel.update { $0.size = CGFloat(newValue) }
                            }
                        ),
                        range: 16...240,
                        lower: "16",
                        upper: "240",
                        readout: "\(Int(viewModel.settings.size.rounded())) px"
                    )
                }
            }

            SettingsCard(title: "Intensity", subtitle: "How bright the click pulse glows.") {
                VStack(alignment: .leading, spacing: 16) {
                    presetSegmented(
                        label: "Intensity Preset",
                        selection: Binding(
                            get: { viewModel.intensityPresetSelection },
                            set: { viewModel.applyIntensityPresetSelection($0) }
                        ),
                        options: ClickSettingOptions.intensityPresets
                    )

                    modernSlider(
                        label: "Intensity",
                        value: Binding(
                            get: { Double(viewModel.settings.intensity) },
                            set: { newValue in
                                viewModel.update { $0.intensity = CGFloat(newValue) }
                            }
                        ),
                        range: 0.05...2.0,
                        lower: "Subtle",
                        upper: "Beacon",
                        readout: String(format: "%.2f", Double(viewModel.settings.intensity))
                    )
                }
            }

            SettingsCard(title: "Duration", subtitle: "How long each pulse stays visible.") {
                VStack(alignment: .leading, spacing: 16) {
                    presetSegmented(
                        label: "Duration Preset",
                        selection: Binding(
                            get: { viewModel.durationPresetSelection },
                            set: { viewModel.applyDurationPresetSelection($0) }
                        ),
                        options: ClickSettingOptions.durationPresets
                    )

                    modernSlider(
                        label: "Duration",
                        value: Binding(
                            get: { viewModel.settings.duration },
                            set: { newValue in
                                viewModel.update { $0.duration = newValue }
                            }
                        ),
                        range: 0.1...2.0,
                        lower: "0.10s",
                        upper: "2.00s",
                        readout: String(format: "%.2f s", viewModel.settings.duration)
                    )
                }
            }

            SettingsCard(title: "Color", subtitle: "Tint applied to every pulse.") {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        ColorSwatch(color: resolvedColor)
                            .accessibilityHidden(true)
                        Picker("Color", selection: binding(\.colorPreset)) {
                            ForEach(ClickColorPreset.allCases, id: \.rawValue) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    if viewModel.settings.colorPreset == .custom {
                        Divider()

                        Picker("Custom Color Mode", selection: binding(\.customColorMode)) {
                            ForEach(CustomClickColorMode.allCases, id: \.rawValue) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Custom Color Mode")

                        if viewModel.settings.customColorMode == .all {
                            customColorRow(
                                title: "Custom Color",
                                subtitle: "Use one custom color for every click.",
                                color: Binding(
                                    get: { Color(nsColor: viewModel.settings.customColor) },
                                    set: { viewModel.applyCustomColor(NSColor($0)) }
                                )
                            )
                        } else {
                            VStack(spacing: 0) {
                                customColorRow(
                                    title: "Left Click",
                                    subtitle: "Used for left press and release pulses.",
                                    color: customClickColorBinding(.left)
                                )
                                Divider().padding(.vertical, 6)
                                customColorRow(
                                    title: "Right Click",
                                    subtitle: "Used for secondary-button pulses.",
                                    color: customClickColorBinding(.right)
                                )
                                Divider().padding(.vertical, 6)
                                customColorRow(
                                    title: "Middle Click",
                                    subtitle: "Used for center-button pulses.",
                                    color: customClickColorBinding(.middle)
                                )
                                Divider().padding(.vertical, 6)
                                customColorRow(
                                    title: "Drag",
                                    subtitle: "Used for the normal drag trail.",
                                    color: customClickColorBinding(.drag)
                                )
                            }
                        }
                    } else {
                        Divider()

                        ModernRow(title: "Custom Color",
                                  subtitle: "Picking a color switches to Custom automatically.") {
                            ColorPicker(
                                "",
                                selection: Binding(
                                    get: { resolvedColor },
                                    set: { viewModel.applyCustomColor(NSColor($0)) }
                                ),
                                supportsOpacity: false
                            )
                            .labelsHidden()
                            .accessibilityLabel("Custom Color Picker")
                        }
                    }
                }
            }
        }
    }

    private var eventsPane: some View {
        SettingsCard {
            VStack(spacing: 0) {
                ModernRow(title: "Laser Pointer Mode",
                          subtitle: "Show a fading red pointer and draw temporary strokes while dragging.") {
                    Toggle("", isOn: binding(\.showLaserPointer))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Laser Pointer Mode")
                }
                Divider().padding(.vertical, 6)
                ModernRow(title: "Show Live Keyboard Shortcuts",
                          subtitle: "Display shortcut combinations beside the pointer while you use them.") {
                    Toggle("", isOn: binding(\.showLiveKeyboardShortcuts))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Show Live Keyboard Shortcuts")
                }
                Divider().padding(.vertical, 6)
                ModernRow(title: "Show Press",
                          subtitle: "Highlight when the mouse button goes down.") {
                    Toggle("", isOn: binding(\.showPress))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Show Press")
                }
                Divider().padding(.vertical, 6)
                ModernRow(title: "Show Release",
                          subtitle: "Highlight when the mouse button releases.") {
                    Toggle("", isOn: binding(\.showRelease))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Show Release")
                }
                Divider().padding(.vertical, 6)
                ModernRow(title: "Show Right Click",
                          subtitle: "Highlight secondary-button clicks.") {
                    Toggle("", isOn: binding(\.showRightClick))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Show Right Click")
                }
                Divider().padding(.vertical, 6)
                    ModernRow(title: "Show Middle Click",
                          subtitle: "Highlight center-button clicks.") {
                      Toggle("", isOn: binding(\.showMiddleClick))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Show Middle Click")
                    }
                    Divider().padding(.vertical, 6)
                ModernRow(title: "Show Drag",
                          subtitle: viewModel.settings.showLaserPointer
                              ? "Laser Pointer Mode replaces the normal drag trail."
                              : "Trail pointer movement while dragging.") {
                    Toggle("", isOn: binding(\.showDrag))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .accessibilityLabel("Show Drag")
                        .disabled(viewModel.settings.showLaserPointer)
                }
            }
        }
    }

    private var shortcutsPane: some View {
        VStack(spacing: 16) {
            if viewModel.hasHotKeyRegistrationIssues {
                SettingsCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Some shortcuts could not be registered globally.", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)

                        ForEach(viewModel.hotKeyRegistrationIssueSummary, id: \.self) { line in
                            Text(line)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            SettingsCard(title: "Global Shortcuts") {
                VStack(spacing: 0) {
                    ForEach(Array(ClickShortcutAction.allCases.enumerated()), id: \.element) { index, action in
                        ShortcutRecorderField(
                            label: action.title,
                            currentBinding: viewModel.shortcutBinding(for: action),
                            defaultBinding: action.defaultBinding,
                            errorMessage: viewModel.shortcutError(for: action),
                            onRecord: { binding in
                                viewModel.updateShortcutBinding(binding, for: action)
                            },
                            onReset: {
                                viewModel.resetShortcutBinding(for: action)
                            },
                            onClear: {
                                viewModel.clearShortcutBinding(for: action)
                            }
                        )
                        .padding(.vertical, 4)

                        if index < ClickShortcutAction.allCases.count - 1 {
                            Divider().padding(.vertical, 4)
                        }
                    }
                }
            }

            SettingsCard {
                ModernRow(title: "Reset All Shortcuts",
                          subtitle: "Restore the ClickLight toggle shortcut and disable optional shortcuts.") {
                    Button(role: .destructive) {
                        showShortcutResetConfirmation = true
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .controlSize(.regular)
                }
            }

        }
        .confirmationDialog(
            "Reset all keyboard shortcuts?",
            isPresented: $showShortcutResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                viewModel.resetAllShortcutBindings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores the ClickLight toggle shortcut and disables every optional shortcut.")
        }
    }

    // MARK: - Helpers

    private var resolvedColor: Color {
        if viewModel.settings.colorPreset == .custom {
            return Color(nsColor: viewModel.settings.customColor)
        }
        if let color = viewModel.settings.colorPreset.color {
            return Color(nsColor: color)
        }
        return Color.accentColor
    }

    private func binding<T>(_ keyPath: WritableKeyPath<ClickSettings, T>) -> Binding<T> {
        Binding(
            get: { viewModel.settings[keyPath: keyPath] },
            set: { newValue in
                viewModel.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    @ViewBuilder
    private func presetSegmented(
        label: String,
        selection: Binding<String>,
        options: [ClickNumericPreset]
    ) -> some View {
        Picker(label, selection: selection) {
            ForEach(options, id: \.value) { preset in
                Text(preset.title).tag(String(preset.value))
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private func modernSlider(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        lower: String,
        upper: String,
        readout: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(lower)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Slider(value: value, in: range)
                    .accessibilityLabel(label)
                    .accessibilityValue(readout)
                Text(upper)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            HStack {
                Spacer()
                Text(readout)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.secondary.opacity(0.12))
                    )
                    .accessibilityHidden(true)
            }
        }
    }

}

// MARK: - Reusable Components

private struct SettingsCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    @ViewBuilder var content: () -> Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct ModernRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.medium))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            trailing()
        }
        .padding(.vertical, 6)
    }
}

private struct ColorSwatch: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color)
            .frame(width: 28, height: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }
}

private struct ClickPreviewPad: NSViewRepresentable {
    let settings: ClickSettings

    func makeNSView(context: Context) -> InteractiveClickPreviewView {
        InteractiveClickPreviewView(settings: settings)
    }

    func updateNSView(_ nsView: InteractiveClickPreviewView, context: Context) {
        nsView.apply(settings: settings)
    }
}

private final class InteractiveClickPreviewView: NSView {
    private let overlayView: ClickOverlayView
    private var settings: ClickSettings

    init(settings: ClickSettings) {
        self.settings = settings
        self.overlayView = ClickOverlayView(
            screenFrame: CGRect(x: 0, y: 0, width: 200, height: 116),
            settings: settings
        )
        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.55).cgColor

        overlayView.autoresizingMask = [.width, .height]
        addSubview(overlayView)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        overlayView.frame = bounds
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    func apply(settings: ClickSettings) {
        self.settings = settings
        overlayView.apply(settings: settings)
    }

    override func mouseDown(with event: NSEvent) {
        show(.leftDown, event: event)
    }

    override func mouseUp(with event: NSEvent) {
        show(.leftUp, event: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        show(.rightDown, event: event)
    }

    override func rightMouseUp(with event: NSEvent) {
        show(.rightUp, event: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        guard event.buttonNumber == 2 else { return }
        show(.middleDown, event: event)
    }

    override func otherMouseUp(with event: NSEvent) {
        guard event.buttonNumber == 2 else { return }
        show(.middleUp, event: event)
    }

    override func mouseDragged(with event: NSEvent) {
        show(.drag, event: event)
    }

    override func rightMouseDragged(with event: NSEvent) {
        show(.drag, event: event)
    }

    override func otherMouseDragged(with event: NSEvent) {
        guard event.buttonNumber == 2 else { return }
        show(.drag, event: event)
    }

    private func show(_ kind: ClickKind, event: NSEvent) {
        guard settings.isEnabled else { return }
        let location = convert(event.locationInWindow, from: nil)
        overlayView.show(
            event: ClickEvent(
                kind: kind,
                location: location,
                timestamp: CACurrentMediaTime()
            ),
            settings: settings
        )
    }
}

private enum SettingsPane: String, CaseIterable, Hashable {
    case general
    case events
    case style
    case shortcuts

    var title: String {
        switch self {
        case .general:
            return "General"
        case .style:
            return "Visual Style"
        case .shortcuts:
            return "Keyboard Shortcuts"
        case .events:
            return "Event Visibility"
        }
    }

    var subtitle: String {
        switch self {
        case .general:
            return "Enable ClickLight, set startup behavior, and manage permissions."
        case .style:
            return "Size, intensity, duration, and color of click pulses."
        case .shortcuts:
            return "Set global shortcuts."
        case .events:
            return "Choose which mouse interactions trigger a pulse."
        }
    }

    var icon: String {
        switch self {
        case .general:
            return "gearshape"
        case .style:
            return "paintpalette"
        case .shortcuts:
            return "keyboard"
        case .events:
            return "cursorarrow.click.2"
        }
    }
}
