# ClickLight

A small macOS menu bar app that highlights your clicks, for things like live demos or when you want more visibility into what you are clicking.

Screen recorders like Screen Studio and CleanShot can add click effects to recordings. ClickLight is for the moments happening live, before there is a recording to polish.

## Demo

![ClickLight showing click highlights from the macOS menu bar](docs/assets/ClickLight.gif)

## Use Cases

- Live product demos where viewers need to follow exactly what you clicked
- UX reviews where the delay between click and response matters (the original motivation for ClickLight)
- Bug reports where a recording should show both the action and the app behavior
- Tutorials, workshops, and conference talks where pointer movement alone is easy to miss
- Pairing with a larger macOS pointer so clicks stay visible in screen recordings

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

Release scaffolding is included for Developer ID signing, notarization, Sparkle auto-updates, GitHub Releases, and a Homebrew cask.

See [Releasing](docs/RELEASING.md). Until the first release is published, recent changes are tracked in the [Changelog](CHANGELOG.md).

## Uninstall

> **Manual uninstall**
> If you installed ClickLight manually, see [Remove Manual Install](docs/MANUAL_INSTALL.md#remove-manual-install).

If you installed ClickLight with Homebrew:

```bash
brew uninstall --cask clicklight
```

## License

MIT. See [LICENSE](LICENSE).
