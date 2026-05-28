# ClickLight — Agent Instructions

macOS menu-bar app that highlights mouse clicks for live demos and screen sharing. Native Swift/AppKit, no Xcode project required.

## Build & Run

```bash
# Build the app bundle
./build-app.sh

# Iterate quickly after source changes
./build-app.sh && { pkill -x ClickLight || true; open ClickLight.app; }

# Inspect UserDefaults during development
defaults read com.aurorascharff.ClickLight
```

No test suite exists — verify behavior manually using **Menu Bar → Test Pulse at Pointer** and the Settings window. See [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) for full setup.

## Architecture

All UI state is `@MainActor`. Click events flow through a notification-based pipeline:

```
ClickEventTap (CGEventTap + NSEvent fallback)
  → NotificationCenter didReceiveClickEvent
  → AppDelegate (filters settings-window hits)
  → OverlayCoordinator (per-screen ClickOverlayWindow)
  → ClickOverlayView (CoreGraphics pulse/laser animation)
```

| Component | Responsibility |
|-----------|---------------|
| `ClickEventTap` | Global mouse capture; primary CGEventTap + NSEvent fallback |
| `OverlayCoordinator` | One `ClickOverlayWindow` per screen; deduplicates events (3 px / 0.1 s) |
| `ClickOverlayView` | CoreGraphics drawing; timer-driven animation loop |
| `SettingsStore` | UserDefaults wrapper; posts `didChangeNotification` on write |
| `StatusController` | Menu-bar NSStatusItem; throttled menu rebuild (0.1 s debounce) |
| `AppDelegate` | Wires all components; handles screen change notifications |

## Key Conventions

- **UI mutations on the main actor** — keep AppKit and settings mutations on the main actor; event capture forwards UI work onto the main queue.
- **Notifications for cross-component events** — settings changes and click events use `NotificationCenter`.
- **Value types for data, classes for controllers** — `ClickEvent`, `ClickSettings`, `ClickKind` are structs/enums; controllers are classes.
- **Settings access** — read via `settingsStore.settings.<property>`; write by replacing the whole struct: `settingsStore.settings = newSettings`.
- **Adding a new click kind** — update `ClickKind` enum, `ClickEventTap` mapping, `ClickLightSettingsView` toggle, and `ClickOverlayView` drawing logic.
- **Adding a new setting** — add to `ClickSettings` struct with a default in `ClickSettings.defaults`; persist in `SettingsStore`.
- **Overlay windows** — borderless, transparent, `ignoresMouseEvents = true`, `.screenSaver` level, `.canJoinAllSpaces`.
- **No Xcode project** — build via `swift build` orchestrated by `build-app.sh`; version is read from the latest git tag.

## Important Pitfalls

- **Accessibility permission** is required for `CGEventTap`. After granting it in System Settings, the user must quit and reopen the app. Moving the `.app` bundle to a new path also requires re-granting.
- **CoreGraphics drawing only** — `ClickOverlayView` uses raw `CGContext`; do not introduce `NSBezierPath` or layer-backed drawing.
- **Laser pointer is CPU-intensive** — enabling it adds `mouseMoved` to the event filter; be careful adding more processing inside the move handler.
- **Screen IDs are not stable across reboots** — `OverlayCoordinator` uses `NSScreenNumber` from `deviceDescription`, sufficient for runtime but not for persistence.
- **Pulses in-flight keep old settings** — `refreshSettings()` applies immediately to new pulses; existing animations finish with their original parameters.

## Releasing

The tag-triggered GitHub Actions pipeline handles signing, notarization, and GitHub Release publication, then opens a pull request for Sparkle `appcast.xml` and Homebrew cask updates. See [docs/RELEASING.md](docs/RELEASING.md).
