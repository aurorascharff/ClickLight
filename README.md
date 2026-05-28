# ClickLight

A small macOS menu bar app that highlights your clicks during live demos, screen sharing, UX reviews, and other moments where people need to follow what you are doing.

Screen recorders like Screen Studio and CleanShot can add click effects after the fact. ClickLight is for the live moment itself, when you need the audience to see exactly when you clicked without interrupting your flow.

## Demo

![ClickLight showing click highlights from the macOS menu bar](docs/assets/ClickLight.gif)

## Use Cases

- Live product demos where viewers need to follow exactly what you clicked
- UX reviews where the delay between click and response matters (the original motivation for ClickLight)
- Bug reports where a recording should show both the action and the app behavior
- Tutorials, workshops, and conference talks where pointer movement alone is easy to miss
- Pairing with a larger macOS pointer so clicks stay visible in live demos and recordings

## Install

With Homebrew:

```bash
brew tap aurorascharff/clicklight https://github.com/aurorascharff/ClickLight
brew install --cask aurorascharff/clicklight/clicklight
```

Homebrew installs are updated with `brew upgrade --cask clicklight`.

Prefer not to use Homebrew? Download `ClickLight.zip` from [GitHub Releases](https://github.com/aurorascharff/ClickLight/releases).

> **Manual install**
> If you want to build ClickLight from source or iterate on it locally, use [Manual Install](docs/MANUAL_INSTALL.md).

## Features

- Click highlights across macOS apps
- Separate visuals for press, release, right-click, and drag
- Optional laser pointer mode with fading freehand strokes while dragging
- Dedicated settings window with sliders + presets for size, duration, intensity, and color
- Custom color picker in Settings
- Menu-bar quick presets for size, duration, intensity, and color
- Optional compact menu-bar icon
- Test pulse for verifying overlay behavior
- Native Swift/AppKit app
- No Xcode project required

## Permissions

ClickLight requires Accessibility permission to detect clicks outside its own menu-bar app. You will be prompted on first launch, or grant it manually in:

**System Settings -> Privacy & Security -> Accessibility**

After enabling permission, quit ClickLight from the menu bar and reopen it.

Tip: for recorded demos or presentations, pair ClickLight with a larger macOS pointer in **System Settings -> Accessibility -> Display -> Pointer**.

## Modify It

ClickLight is personal software: one small presentation annoyance, fixed directly. The project is intentionally small so you or an agent can change it without much ceremony.

Start with [Local Development](docs/LOCAL_DEVELOPMENT.md).

## Releasing

Releases are signed, notarized, published to GitHub Releases, installable with Homebrew, and prepared for Sparkle updates.

See [Releasing](docs/RELEASING.md). What's new is tracked in [GitHub Releases](https://github.com/aurorascharff/ClickLight/releases).

## Uninstall

```bash
brew uninstall --cask clicklight
```

To remove ClickLight preferences too:

```bash
brew uninstall --cask --zap clicklight
```

> **Manual uninstall**
> If you installed ClickLight manually from source, use [Remove Manual Install](docs/MANUAL_INSTALL.md#remove-manual-install).

## License

MIT. See [LICENSE](LICENSE).
