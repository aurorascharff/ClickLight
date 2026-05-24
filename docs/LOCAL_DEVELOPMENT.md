# Local Development

This project is meant to be easy to modify. The app is small, native Swift/AppKit, and built from the command line.

ClickLight does not use an `.xcodeproj` or `.xcworkspace`. It is a Swift Package Manager executable wrapped into a standard macOS `.app` bundle by `build-app.sh`.

## Prerequisites

Install Apple Command Line Tools if Swift is not already available:

```bash
xcode-select --install
swift --version
```

## Iterate

After changing Swift files:

```bash
./build-app.sh
pkill -x ClickLight
open ClickLight.app
```

If `pkill` does not find a running app, that is fine. It just means ClickLight was not already open.

For a persistent local install after your changes, follow [Manual Install](MANUAL_INSTALL.md).

## Build Flow

`Package.swift` defines one executable target:

```swift
.executableTarget(
    name: "ClickLight",
    path: "Sources/ClickLight"
)
```

`swift build -c release` compiles the binary to:

```text
.build/release/ClickLight
```

`build-app.sh` then creates:

```text
ClickLight.app
└── Contents
    ├── Info.plist
    ├── MacOS
    │   └── ClickLight
    ├── Frameworks
    │   └── Sparkle.framework
    └── Resources
```

and signs the app bundle. Local builds use ad-hoc signing by default. Release builds can use Developer ID signing and notarization when the required Apple credentials are configured.

This works without Xcode because Xcode is not the compiler. The app uses AppKit and CoreGraphics APIs directly from Swift, and Swift Package Manager can build it from the command line.

## Useful Files

- `Sources/ClickLight/ClickEventTap.swift`: global mouse capture
- `Sources/ClickLight/OverlayCoordinator.swift`: one overlay per screen
- `Sources/ClickLight/ClickOverlayView.swift`: pulse drawing and animation
- `Sources/ClickLight/StatusController.swift`: menu-bar UI
- `Sources/ClickLight/SettingsStore.swift`: saved preferences
- `Sources/ClickLight/UpdateChecker.swift`: Sparkle update checks
- `Info.plist`: app bundle metadata
- `build-app.sh`: command-line app bundle builder

## Debugging

Run the binary directly if the app does not appear in the menu bar:

```bash
ClickLight.app/Contents/MacOS/ClickLight
```

Other useful checks:

```bash
pgrep -fl ClickLight
defaults read com.aurorascharff.ClickLight
```

To remove a manually installed app and reset preferences, see [Manual Install](MANUAL_INSTALL.md#remove-manual-install).
