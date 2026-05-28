import AppKit
import SwiftUI

struct ClickLightSettingsView: View {
    @ObservedObject var viewModel: ClickLightSettingsViewModel
    @State private var selectedPane: SettingsPane = .general
    @State private var showResetConfirmation = false
    @State private var showShortcutResetConfirmation = false

    var body: some View {
        NavigationSplitView {
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
                        case .menuBar:
                            menuBarPane
                        case .system:
                            systemPane
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

            SettingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Tip")
                            .font(.subheadline.weight(.semibold))
                    } icon: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                    }
                    Text("Adjust visuals in **Visual Style**. Quick presets stay synced with the menu bar — slider tweaks show as **Custom**.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
            SettingsCard {
                ModernRow(title: "Preview",
                          subtitle: "Show the current pulse style at the pointer.") {
                    Button {
                        viewModel.previewPulse()
                    } label: {
                        Label("Preview Pulse", systemImage: "cursorarrow.click.2")
                    }
                    .controlSize(.regular)
                }
            }

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

            SettingsCard(title: "Global Shortcuts", subtitle: "These shortcuts work system-wide. At least one modifier key is required.") {
                VStack(spacing: 0) {
                    ForEach(Array(ClickShortcutAction.allCases.enumerated()), id: \.element) { index, action in
                        ShortcutRecorderField(
                            label: action.title,
                            subtitle: action.subtitle,
                            currentBinding: viewModel.shortcutBinding(for: action),
                            defaultBinding: action.defaultBinding,
                            errorMessage: viewModel.shortcutError(for: action),
                            onRecord: { binding in
                                viewModel.updateShortcutBinding(binding, for: action)
                            },
                            onReset: {
                                viewModel.resetShortcutBinding(for: action)
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
                          subtitle: "Restore default keybindings for every shortcut action.") {
                    Button(role: .destructive) {
                        showShortcutResetConfirmation = true
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .controlSize(.regular)
                }
            }

            SettingsCard(title: "Fixed Shortcuts", subtitle: "These shortcuts are built-in and cannot be changed.") {
                VStack(spacing: 0) {
                    fixedShortcutRow(label: "Open Settings", keys: "⌘,")
                    Divider().padding(.vertical, 6)
                    fixedShortcutRow(label: "Quit ClickLight", keys: "⌘Q")
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
            Text("This restores all shortcut bindings in this pane to their default values.")
        }
    }

    private var menuBarPane: some View {
        SettingsCard {
            ModernRow(title: "Show Menu Bar Text",
                      subtitle: "Display the “ClickLight” label next to the icon.") {
                Toggle("", isOn: binding(\.showMenuBarText))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .accessibilityLabel("Show Menu Bar Text")
            }
        }
    }

    private var systemPane: some View {
        VStack(spacing: 16) {
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

    @ViewBuilder
    private func fixedShortcutRow(label: String, keys: String) -> some View {
        HStack {
            Text(label)
                .font(.callout.weight(.medium))
            Spacer()
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
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

private enum SettingsPane: String, CaseIterable, Hashable {
    case general
    case style
    case shortcuts
    case events
    case menuBar
    case system

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
        case .menuBar:
            return "Menu Bar"
        case .system:
            return "System"
        }
    }

    var subtitle: String {
        switch self {
        case .general:
            return "Toggle ClickLight and learn how settings work."
        case .style:
            return "Size, intensity, duration, and color of click pulses."
        case .shortcuts:
            return "Record custom global shortcuts for toggling ClickLight modes."
        case .events:
            return "Choose which mouse interactions trigger a pulse."
        case .menuBar:
            return "Adjust the menu bar status item appearance."
        case .system:
            return "Launch at login and Accessibility permission."
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
        case .menuBar:
            return "menubar.rectangle"
        case .system:
            return "lock.shield"
        }
    }
}
