# Contributing to ClickLight

Thanks for helping improve ClickLight.

## Get Started

1. Fork the repository and create a branch for your change.
2. Follow [Local Development](docs/LOCAL_DEVELOPMENT.md) to build and run the app.
3. Keep changes focused and update documentation when behavior changes.
4. Open a pull request against `main`.

## Verify Changes

Build the app from the repository root:

```bash
./build-app.sh
```

Launch the built app and manually exercise the behavior you changed. Useful checks include:

- the menu bar controls and Settings window
- **Test Pulse at Pointer**
- click indicators in another app after granting Accessibility permission
- any new keyboard shortcut or pointer interaction

There is currently no automated test suite, so include your manual test steps in the pull request.

## Pull Requests

- Explain what changed and why.
- Include screenshots or a short recording for visible UI changes.
- Do not commit signing credentials, private keys, generated app bundles, or local system files.
- Keep release changes separate unless you are maintaining the release workflow itself.

For security vulnerabilities, do not open a public issue. See [SECURITY.md](SECURITY.md).
