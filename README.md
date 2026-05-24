# ClickLight

A macOS menu bar app that highlights your clicks during live demos, so viewers can see exactly when you pressed even if the UI responds slowly.

## Demo

![ClickLight showing click highlights from the macOS menu bar](docs/assets/ClickLight.gif)

## Install

> **Release status**
> Homebrew installation is the intended install path, but the first signed release is pending Apple Developer enrollment. Until the first release is published, use [Manual Install](docs/MANUAL_INSTALL.md).

After the first signed release is published, install with Homebrew:

```bash
brew tap aurorascharff/clicklight https://github.com/aurorascharff/ClickLight
brew install --cask aurorascharff/clicklight/clicklight
```

## Features

- Click highlights across macOS apps
- Separate visuals for press, release, right-click, and drag
- Menu-bar controls for size, duration, and intensity
- Test pulse for verifying overlay behavior
- Native Swift/AppKit app
- No Xcode project required

## Permissions

ClickLight requires Accessibility permission to detect clicks outside its own menu-bar app. You will be prompted on first launch, or grant it manually in:

**System Settings -> Privacy & Security -> Accessibility**

After enabling permission, quit ClickLight from the menu bar and reopen it.

## Modify It

ClickLight is personal software: one small presentation annoyance, fixed directly. The project is intentionally small so you or an agent can change it without much ceremony.

Start with [Local Development](docs/LOCAL_DEVELOPMENT.md).

## Releasing

Release scaffolding is included for Developer ID signing, notarization, Sparkle auto-updates, GitHub Releases, and a Homebrew cask.

See [Releasing](docs/RELEASING.md).

## Uninstall

```bash
brew uninstall --cask clicklight
```

## License

MIT. See [LICENSE](LICENSE).
