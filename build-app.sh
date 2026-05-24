#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ClickLight"
BUNDLE_IDENTIFIER="com.aurorascharff.ClickLight"
CONFIGURATION="${CONFIGURATION:-release}"
NOTARIZE=false

for arg in "$@"; do
    case "$arg" in
        --release)
            CONFIGURATION="release"
            ;;
        --notarize)
            NOTARIZE=true
            ;;
        *)
            echo "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
APP_DIR="$ROOT_DIR/$APP_NAME.app"
ZIP_PATH="$ROOT_DIR/$APP_NAME.zip"

VERSION="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.1.0")"

swift build -c "$CONFIGURATION"

rm -rf "$APP_DIR" "$ZIP_PATH"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$APP_DIR/Contents/Frameworks"

cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER" "$APP_DIR/Contents/Info.plist"

cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

SPARKLE_PATH="$(find "$ROOT_DIR/.build" -name "Sparkle.framework" -type d | head -1)"
if [ -n "$SPARKLE_PATH" ]; then
    cp -a "$SPARKLE_PATH" "$APP_DIR/Contents/Frameworks/"
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true
fi

SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
echo "Code signing with identity: $SIGNING_IDENTITY"

if [ -d "$APP_DIR/Contents/Frameworks/Sparkle.framework" ]; then
    SPARKLE_VERSION_DIR="$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B"
    codesign --force --sign "$SIGNING_IDENTITY" "$SPARKLE_VERSION_DIR/Sparkle"
    codesign --force --sign "$SIGNING_IDENTITY" "$SPARKLE_VERSION_DIR/Updater.app"
    find "$SPARKLE_VERSION_DIR/XPCServices" -name "*.xpc" -exec codesign --force --sign "$SIGNING_IDENTITY" {} \;
fi

if [ "$SIGNING_IDENTITY" = "-" ]; then
    codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_DIR"
else
    codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_DIR"
fi

if [ "$NOTARIZE" = true ]; then
    if [ -z "${APP_STORE_CONNECT_KEY:-}" ] ||
        [ -z "${APP_STORE_CONNECT_KEY_ID:-}" ] ||
        [ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
        echo "Notarization requires APP_STORE_CONNECT_KEY, APP_STORE_CONNECT_KEY_ID, and APP_STORE_CONNECT_ISSUER_ID."
        exit 1
    fi

    KEY_FILE="$(mktemp)"
    echo "$APP_STORE_CONNECT_KEY" > "$KEY_FILE"

    ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
    xcrun notarytool submit "$ZIP_PATH" \
        --key "$KEY_FILE" \
        --key-id "$APP_STORE_CONNECT_KEY_ID" \
        --issuer "$APP_STORE_CONNECT_ISSUER_ID" \
        --wait
    xcrun stapler staple "$APP_DIR"

    rm "$KEY_FILE" "$ZIP_PATH"
fi

echo "Built $APP_DIR"
