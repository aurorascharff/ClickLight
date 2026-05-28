# Releasing

ClickLight releases are built with Developer ID signing, notarization, Sparkle update signing, GitHub Releases, and a Homebrew cask.

## Required Apple Setup

You need an active Apple Developer Program membership.

Create:

- Developer ID Application certificate
- App Store Connect API key
- Sparkle EdDSA key pair

## GitHub Secrets

Add these repository secrets:

```text
CERTIFICATE_P12
CERTIFICATE_PASSWORD
SIGNING_IDENTITY
APP_STORE_CONNECT_KEY
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
SPARKLE_PRIVATE_KEY
```

`SIGNING_IDENTITY` should look like:

```text
Developer ID Application: Your Name (TEAMID)
```

## Sparkle Public Key

The Sparkle public key is stored in `Info.plist`:

```text
SUPublicEDKey
```

The matching private key goes in the `SPARKLE_PRIVATE_KEY` GitHub secret.

## GitHub Environment Approval

Create a GitHub Environment named:

```text
release
```

To add a release approval gate, add yourself as a required reviewer. Verify that the next tagged workflow run pauses for review before relying on this protection.

In **Settings -> Actions -> General**, enable **Allow GitHub Actions to create and approve pull requests**. The release workflow needs permission to open its metadata pull request.

## Release Flow

```bash
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

If the `release` environment requires approval, approve the waiting workflow run in GitHub Actions.

The workflow will:

1. build ClickLight
2. sign and notarize it
3. zip `ClickLight.app`
4. sign the zip for Sparkle
5. create a GitHub Release
6. open a pull request updating `appcast.xml` and `Casks/clicklight.rb`

Review and merge the generated metadata pull request after the release succeeds. That merge makes the new version available through Homebrew upgrades and Sparkle in-app updates without allowing the workflow to push directly to protected `main`.

## Release Notes

GitHub Releases are the public changelog for ClickLight. The workflow creates release notes with:

```bash
gh release create "v${VERSION}" ClickLight.zip --generate-notes
```

The generated notes are organized by `.github/release.yml`. Use labels like `feature`, `bug`, `documentation`, `security`, `maintenance`, and `refactor` on pull requests to place changes in the right section.

## Homebrew Install

Users can install the latest published release with:

```bash
brew tap aurorascharff/clicklight https://github.com/aurorascharff/ClickLight
brew install --cask aurorascharff/clicklight/clicklight
```
