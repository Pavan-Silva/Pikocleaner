#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODEBUILD="${XCODEBUILD:-$(/usr/bin/xcrun --find xcodebuild)}"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-$ROOT_DIR/.build/derived-dmg}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/Builds/Export}"
DMG_PATH="$OUTPUT_DIR/PikoCleaner-unsigned.dmg"
STAGING_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/PikoCleaner-dmg.XXXXXX")"

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

/usr/bin/ditto "$APP_PATH" "$STAGING_DIR/PikoCleaner.app"
/bin/ln -s /Applications "$STAGING_DIR/Applications"
/bin/mkdir -p "$OUTPUT_DIR"
/usr/bin/hdiutil create \
    -volname "Piko Cleaner" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
/usr/bin/hdiutil verify "$DMG_PATH"

printf '\nCreated unsigned test image: %s\n' "$DMG_PATH"
printf 'This image is not Developer ID signed or notarized; Gatekeeper warnings are expected.\n'
