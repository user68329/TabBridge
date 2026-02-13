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

## Requirements

- macOS 14 Sonoma or later
- iCloud account with Safari tabs syncing enabled
- Full Disk Access (to read Safari's iCloud tabs database)

## Building

Open `TabBridge.xcodeproj` in Xcode and build the `TabBridge` scheme.

## How it works

TabBridge reads Safari's local iCloud tabs SQLite database (`CloudTabs.db`) and monitors it for changes. It never modifies the database — read-only access only.
