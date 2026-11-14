# Piko Cleaner

Piko Cleaner is a Mac app uninstaller and cleanup utility built with SwiftUI. It is a
source-available fork of the **Pearcleaner** project, renamed and maintained
independently.

## Highlights

- Persistent vertical **activity rail** for switching between tools, with hover
  labels, a selected state, and an update badge.
- Native **macOS 27 Golden Gate** chrome (edge-to-edge sidebar and uniform toolbar),
  while keeping the Tahoe glass look on macOS 26 and the legacy layout on older
  releases.
- A fully self-contained build: the UI/updater foundation code lives directly in the
  app target instead of being pulled from a remote package.
- No profile/greeting UI, no sponsor links, and no update feed from another project.

## Features

- **App Uninstall** with orphaned-file search
- **File Search**, **Homebrew Manager**, **App Lipo**, **PKG Manager**
- **Plugin Manager**, **Services Manager**, **Apps Updater**
- Drag and drop apps, CLI support, and deep-link automation
- Finder extension for right-click uninstall
- **Sentinel Monitor** for automatic cleanup when apps are moved to the Trash
- Prune unused app translations and strip unneeded architectures
- Custom themes, search directories, and search sensitivity

## Requirements

- macOS 13.0 or later
- Full Disk Access to search for files
- The privileged helper tool to modify system folders

| macOS | Codename | Supported |
|-------|----------|-----------|
| 13.x | Ventura | ✅ |
| 14.x | Sonoma | ✅ |
| 15.x | Sequoia | ✅ |
| 26.x | Tahoe | ✅ |
| 27.x | Golden Gate | ✅ |

Versions prior to macOS 13.0 are not supported because the app relies on newer
Swift and SwiftUI APIs.

## Building

1. Open `PikoCleaner.xcodeproj` in Xcode 27 or later.
2. Select the **PikoCleaner Debug** scheme.
3. Build and run.

From the command line:

```sh
xcodebuild \
  -project PikoCleaner.xcodeproj \
  -scheme "PikoCleaner Debug" \
  -configuration Debug \
  -derivedDataPath .build/derived \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

### Unsigned test DMG

To create a Release build in a drag-to-Applications DMG for testing:

```sh
bash Builds/build-unsigned-dmg.sh
```

The image is written to `Builds/Export/PikoCleaner-unsigned.dmg`. It is not
Developer ID signed or notarized, so macOS Gatekeeper warnings are expected.
This is for testing only, not public distribution.

### Configuration

Fork-specific settings live in `PikoCleaner/Logic/ForkInfo.swift`:

- `repoOwner` / `repoName` — GitHub repository for this fork. While empty, update
  checks, announcements, and repository links stay hidden and no network requests
  are made.
- `usesGoldenGateChrome` — used internally to switch the macOS 27 chrome.

### Command line

The CLI is installed as `piko` in `/usr/local/bin` when enabled in
Settings ▸ General:

```sh
piko --help
piko list-orphaned
piko uninstall /Applications/SomeApp.app
```

The app registers the `piko://` URL scheme for automation and Finder services.

### Dependencies

- [Sparkle](https://github.com/sparkle-project/Sparkle) for app updates
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) for the CLI
- Portions of `PikoCleaner/Foundation` are derived from the MIT-licensed
  AlinFoundation library (see `THIRD_PARTY_NOTICES.md`)

## License

The codebase is derived from Pearcleaner and remains licensed under **Apache 2.0
with the Commons Clause**. You may use, modify, and redistribute the source, but
the license prohibits monetizing it or modified versions of it. See
[LICENSE.md](LICENSE.md) for the full text and attribution.

This fork retains the original copyright and license notices as required. It is
not affiliated with or endorsed by the original project.
