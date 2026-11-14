# Pearcleaner (personal fork)

An independent, source-available fork of Pearcleaner — a Mac app uninstaller and
cleanup utility built with SwiftUI.

This fork focuses on:

- Native **macOS 27 Golden Gate** chrome (edge-to-edge sidebar and uniform toolbar),
  while keeping the existing Tahoe glass look on macOS 26 and the legacy layout on
  older releases.
- A fully self-contained build: the UI/updater foundation code lives directly in the
  app target instead of being pulled from a remote package.
- No profile/greeting UI, no sponsor links, and no connections to the original
  project's GitHub repository or update feed.

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

1. Open `Pearcleaner.xcodeproj` in Xcode 27 or later.
2. Select the **Pearcleaner Debug** scheme.
3. Build and run.

From the command line:

```sh
xcodebuild \
  -project Pearcleaner.xcodeproj \
  -scheme "Pearcleaner Debug" \
  -configuration Debug \
  -derivedDataPath .build/derived \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

### Configuration

Fork-specific settings live in `Pearcleaner/Logic/ForkInfo.swift`:

- `repoOwner` / `repoName` — GitHub repository for this fork. While empty, update
  checks, announcements, and repository links stay hidden and no network requests
  are made.
- `usesGoldenGateChrome` — used internally to switch the macOS 27 chrome.

### Dependencies

- [Sparkle](https://github.com/sparkle-project/Sparkle) for app updates
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) for the CLI
- Portions of `Pearcleaner/Foundation` are derived from the MIT-licensed
  AlinFoundation library (see `THIRD_PARTY_NOTICES.md`)

## License

Pearcleaner is licensed under **Apache 2.0 with the Commons Clause**. You may use,
modify, and redistribute the source, but the license prohibits monetizing
Pearcleaner or modified versions of it. See [LICENSE.md](LICENSE.md) for the full
text and attribution.

This fork retains the original copyright and license notices as required. It is
not affiliated with or endorsed by the original project.
