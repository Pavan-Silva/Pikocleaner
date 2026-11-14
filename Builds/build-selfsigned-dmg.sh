#!/bin/bash
#
# Build a Release DMG whose app is ad-hoc signed locally and which carries the
# self-sign/install script for later use on any Mac without developer credentials.
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODEBUILD="${XCODEBUILD:-$(/usr/bin/xcrun --find xcodebuild)}"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-$ROOT_DIR/.build/derived-selfsigned-dmg}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/Builds/Export}"
STAGING_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/PikoCleaner-selfsigned-dmg.XXXXXX")"

cleanup() {
    /bin/rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$XCODEBUILD" \
    -project "$ROOT_DIR/PikoCleaner.xcodeproj" \
    -scheme "PikoCleaner Release" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/PikoCleaner.app"
if [[ ! -d "$APP_PATH" ]]; then
    printf 'Expected app bundle not found: %s\n' "$APP_PATH" >&2
    exit 1
fi

VERSION="$(
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
        "$APP_PATH/Contents/Info.plist"
)"
DMG_PATH="$OUTPUT_DIR/PikoCleaner-$VERSION-selfsigned.dmg"

/bin/mkdir -p "$STAGING_DIR" "$OUTPUT_DIR"

/usr/bin/ditto "$APP_PATH" "$STAGING_DIR/PikoCleaner.app"

printf '\nAd-hoc signing the staged app...\n'
/bin/bash "$ROOT_DIR/Builds/self-sign.sh" --sign-only "$STAGING_DIR/PikoCleaner.app"

# The same script is included in the image so the app can be re-signed and
# installed later, for example after moving the DMG to another Mac.
/bin/cp "$ROOT_DIR/Builds/self-sign.sh" \
    "$STAGING_DIR/Sign and Install Piko Cleaner.command"
/bin/chmod +x "$STAGING_DIR/Sign and Install Piko Cleaner.command"

/bin/ln -s /Applications "$STAGING_DIR/Applications"

/bin/cat > "$STAGING_DIR/README.txt" <<EOF
Piko Cleaner $VERSION
=====================

Drag PikoCleaner.app to the Applications folder, then open it.

If macOS blocks the app, or if you want to re-sign it before installing,
double-click:

    Sign and Install Piko Cleaner.command

The command signs PikoCleaner.app ad-hoc with codesign and installs the signed
copy in /Applications. It needs no Apple developer account, certificate, or
network access, so it works on any Mac. It can be copied out of this image and
reused later with a different PikoCleaner.app.

The app is not signed with an Apple Developer ID and is not notarized, so
Gatekeeper warnings are expected. This image is intended for local use, not for
public distribution.
EOF

/usr/bin/hdiutil create \
    -volname "Piko Cleaner" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

/usr/bin/hdiutil verify "$DMG_PATH"

printf '\nCreated self-signed image: %s\n' "$DMG_PATH"
printf 'The app and the self-sign script are both inside the image.\n'
