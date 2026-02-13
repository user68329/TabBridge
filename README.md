# TabBridge

Your Safari iCloud Tabs, instantly accessible. See every open tab from your iPhone, iPad, and Mac in one clean, native macOS interface. Search, filter by device, and launch with a keystroke—without ever opening Safari. Built for speed, designed for focus.

## Features

- **Menu bar + main window** — quick-glance popover from the menu bar, or a full window for power use
- **Search** — filter tabs by title or URL across all devices
- **Device filtering** — show tabs from specific devices only
- **Sort** — by title, domain, or last viewed, ascending or descending
- **Open anywhere** — open tabs in your default browser or pick from any installed browser
- **Quick Look** — preview a tab's page without leaving the app
- **Keyboard-driven** — Return to open, Space to preview, standard multi-select

## Screenshots

| ![Main window](screenshots/01%20Main%20window.png) | ![Right-click menu](screenshots/02%20Right-click%20menu.png) |
|:---:|:---:|
| Browse all iCloud tabs in one window | Open in any installed browser |

## Download

**[Download TabBridge v1.0.0](https://github.com/user68329/TabBridge/releases/latest)** (macOS 14+, Apple Silicon & Intel)

### First launch (Gatekeeper)

TabBridge is ad-hoc signed and not notarized, so macOS will block it on first launch. To open it:

1. **Right-click** (or Control-click) `TabBridge.app` and choose **Open**
2. Click **Open** in the dialog that appears

Or from Terminal:

```bash
xattr -cr /Applications/TabBridge.app
```

You only need to do this once. After the first launch, TabBridge opens normally.

## Requirements

- macOS 14 Sonoma or later
- iCloud account with Safari tabs syncing enabled
- Full Disk Access (to read Safari's iCloud tabs database)

## Building

Open `TabBridge.xcodeproj` in Xcode and build the `TabBridge` scheme.

## How it works

TabBridge reads Safari's local iCloud tabs SQLite database (`CloudTabs.db`) and monitors it for changes. It never modifies the database — read-only access only.
