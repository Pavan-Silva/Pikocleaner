#!/bin/bash
#
# Ad-hoc sign Piko Cleaner so it can be installed and opened on any Mac without
# an Apple developer account, certificate, or notarization.
#
# The build script copies this file into the DMG as
# "Sign and Install Piko Cleaner.command". Double-clicking it from the mounted
# image signs the bundled app and installs it in /Applications.
#
# Usage:
#   ./self-sign.sh [--sign-only | --install] [--force] [--no-open]
#                  [--dest PATH] [--identity NAME] [APP_PATH]
#
# If APP_PATH is omitted, PikoCleaner.app next to this script is used.
#
# By default the app is signed ad-hoc ("-"). An identity can be supplied with
# --identity or SIGN_IDENTITY, but none is required and no developer identity is
# looked up automatically.
#
set -euo pipefail

APP_NAME="PikoCleaner.app"
DEFAULT_DEST="/Applications/PikoCleaner.app"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL=false
SIGN_ONLY=false
FORCE=false
NO_OPEN=false
APP_PATH=""
DEST="$DEFAULT_DEST"
IDENTITY="${SIGN_IDENTITY:--}"

usage() {
    /bin/cat <<EOF
Usage: $(basename "$0") [options] [APP_PATH]

Sign Piko Cleaner with a local identity and optionally install it.

Options:
  --sign-only       Sign the app in place, do not install it.
  --install         Copy and sign the app, then install it in /Applications.
  --force           Replace an existing app without asking.
  --no-open         Do not open the app after installing it.
  --dest PATH       Install destination (default: $DEFAULT_DEST).
  --identity NAME   Optional code-signing identity. Defaults to SIGN_IDENTITY,
                    or "-" for an ad-hoc signature.
  -h, --help        Show this help.

When this script is run from a mounted DMG it defaults to --install.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign-only)
            SIGN_ONLY=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --no-open)
            NO_OPEN=true
            shift
            ;;
        --dest)
            if [[ $# -lt 2 ]]; then
                echo "error: --dest needs a path" >&2
                exit 1
            fi
            DEST="$2"
            shift 2
            ;;
        --identity)
            if [[ $# -lt 2 ]]; then
                echo "error: --identity needs a value" >&2
                exit 1
            fi
            IDENTITY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "error: unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [[ -n "$APP_PATH" ]]; then
                echo "error: only one app path may be supplied" >&2
                exit 1
            fi
            APP_PATH="$1"
            shift
            ;;
    esac
done

if [[ "$SIGN_ONLY" == true && "$INSTALL" == true ]]; then
    echo "error: --sign-only and --install cannot be used together" >&2
    exit 1
fi

if [[ -z "$APP_PATH" ]]; then
    APP_PATH="$SCRIPT_DIR/$APP_NAME"

    # A .command copied into the DMG lives on a read-only volume. In that case
    # the useful default is to sign a copy and install it.
    if [[ "$SCRIPT_DIR" == /Volumes/* ]]; then
        INSTALL=true
    fi
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "error: app bundle not found: $APP_PATH" >&2
    exit 1
fi

APP_PATH="$(cd "$(dirname "$APP_PATH")" && pwd)/$(basename "$APP_PATH")"

if [[ -z "$IDENTITY" ]]; then
    IDENTITY="-"
fi

WORK_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/PikoCleaner-sign.XXXXXX")"
cleanup() {
    /bin/rm -rf "$WORK_DIR"
}
trap cleanup EXIT

MAIN_ENTITLEMENTS="$WORK_DIR/PikoCleaner.entitlements"
FINDER_ENTITLEMENTS="$WORK_DIR/FinderOpen.entitlements"

/bin/cat > "$MAIN_ENTITLEMENTS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.pavansilva.PikoCleaner</string>
	</array>
</dict>
</plist>
PLIST

/bin/cat > "$FINDER_ENTITLEMENTS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.pavansilva.PikoCleaner</string>
	</array>
	<key>com.apple.security.temporary-exception.files.absolute-path.read-only</key>
	<array>
		<string>/</string>
	</array>
</dict>
</plist>
PLIST

sign_item() {
    local path="$1"
    shift

    # Hardened runtime enables library validation, which rejects ad-hoc nested
    # frameworks because they have no common Team ID. Keep it only when a real
    # signing identity was requested.
    local runtime_args=()
    if [[ "$IDENTITY" != "-" ]]; then
        runtime_args=(--options runtime)
    fi

    /usr/bin/codesign \
        --force \
        ${runtime_args[@]+"${runtime_args[@]}"} \
        --timestamp=none \
        --sign "$IDENTITY" \
        "$@" \
        "$path"
}

sign_app() {
    local app="$1"
    local frameworks="$app/Contents/Frameworks"

    # Sparkle contains nested helper code that must be signed before the
    # framework, and the framework must be signed before the app.
    if [[ -d "$frameworks/Sparkle.framework" ]]; then
        local sparkle="$frameworks/Sparkle.framework"
        local sparkle_current="$sparkle/Versions/Current"
        local xpc
        for xpc in "$sparkle_current"/XPCServices/*.xpc; do
            if [[ -d "$xpc" ]]; then
                sign_item "$xpc"
            fi
        done

        local updater
        for updater in "$sparkle_current"/Updater.app; do
            if [[ -d "$updater" ]]; then
                sign_item "$updater"
            fi
        done

        local executable
        for executable in "$sparkle_current"/Autoupdate "$sparkle_current"/Sparkle; do
            if [[ -f "$executable" ]]; then
                sign_item "$executable"
            fi
        done

        sign_item "$sparkle"
    fi

    local extension="$app/Contents/PlugIns/FinderOpen.appex"
    if [[ -d "$extension" ]]; then
        sign_item "$extension" --entitlements "$FINDER_ENTITLEMENTS"
    fi

    local helper="$app/Contents/MacOS/PikoCleanerHelper"
    if [[ -f "$helper" ]]; then
        sign_item "$helper"
    fi

    local sentinel="$app/Contents/MacOS/PikoCleanerSentinel"
    if [[ -f "$sentinel" ]]; then
        sign_item "$sentinel"
    fi

    sign_item "$app" --entitlements "$MAIN_ENTITLEMENTS"

    /usr/bin/codesign --verify --deep --strict --verbose=2 "$app"
}

run_as_root() {
    if [[ -w "$(/usr/bin/dirname "$DEST")" ]]; then
        "$@"
    else
        /usr/bin/sudo "$@"
    fi
}

install_app() {
    local source="$1"
    local dest_parent

    if /usr/bin/pgrep -x PikoCleaner >/dev/null 2>&1; then
        echo "error: Piko Cleaner is running. Quit it and try again." >&2
        exit 1
    fi

    dest_parent="$(/usr/bin/dirname "$DEST")"
    if [[ ! -d "$dest_parent" ]]; then
        if ! /bin/mkdir -p "$dest_parent" 2>/dev/null; then
            /usr/bin/sudo /bin/mkdir -p "$dest_parent"
        fi
    fi

    if [[ -e "$DEST" ]]; then
        if [[ "$FORCE" != true ]]; then
            if [[ -t 0 ]]; then
                local reply
                read -r -p "Replace existing $DEST? [y/N] " reply
                if [[ ! "$reply" =~ ^[Yy]$ ]]; then
                    echo "Cancelled."
                    exit 1
                fi
            else
                echo "error: $DEST already exists; pass --force to replace it" >&2
                exit 1
            fi
        fi
        run_as_root /bin/rm -rf "$DEST"
    fi

    run_as_root /usr/bin/ditto "$source" "$DEST"
    /usr/bin/xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

    echo "Installed: $DEST"
    if [[ "$NO_OPEN" != true ]]; then
        /usr/bin/open "$DEST"
    fi
}

if [[ "$SIGN_ONLY" == true ]]; then
    if [[ ! -w "$APP_PATH" ]]; then
        echo "error: $APP_PATH is not writable; use --install instead" >&2
        exit 1
    fi

    echo "Signing with: $IDENTITY"
    sign_app "$APP_PATH"
    echo "Signed: $APP_PATH"
    exit 0
fi

if [[ "$INSTALL" == true ]]; then
    SIGN_TARGET="$WORK_DIR/$APP_NAME"
    /usr/bin/ditto "$APP_PATH" "$SIGN_TARGET"

    echo "Signing with: $IDENTITY"
    sign_app "$SIGN_TARGET"
    install_app "$SIGN_TARGET"
    exit 0
fi

if [[ ! -w "$APP_PATH" ]]; then
    echo "error: $APP_PATH is not writable; use --install or --sign-only with a writable copy" >&2
    exit 1
fi

echo "Signing with: $IDENTITY"
sign_app "$APP_PATH"
echo "Signed: $APP_PATH"
