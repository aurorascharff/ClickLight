# Releasing

ClickLight has release scaffolding for Developer ID signing, notarization, Sparkle updates, GitHub Releases, and a Homebrew cask.

Until the first release succeeds, the Homebrew cask contains placeholder version and checksum values, and Sparkle is disabled by the placeholder public key in `Info.plist`.

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

Generate a Sparkle key pair with Sparkle's `generate_keys` tool.

Put the public key in `Info.plist`:

```text
SUPublicEDKey
```

The private key goes in the `SPARKLE_PRIVATE_KEY` GitHub secret.

The app intentionally disables update checks while `SUPublicEDKey` is still set to:

```text
REPLACE_WITH_SPARKLE_PUBLIC_ED_KEY
```

## GitHub Environment Approval

Create a GitHub Environment named:

```text
release
```

Add yourself as a required reviewer. This means a pushed tag cannot publish a signed release until you approve it.

## Release Flow

```bash
git tag v0.1.0
git push origin v0.1.0
```

Then approve the `release` environment in GitHub Actions.

The workflow will:

1. build ClickLight
2. sign and notarize it
3. zip `ClickLight.app`
4. sign the zip for Sparkle
5. update `appcast.xml`
6. update `Casks/clicklight.rb`
7. create a GitHub Release

## Homebrew Install

After the first release updates `Casks/clicklight.rb` with a real version and SHA, users can install with:

```bash
brew tap aurorascharff/clicklight https://github.com/aurorascharff/ClickLight
brew install --cask aurorascharff/clicklight/clicklight
```
