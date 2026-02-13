import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.setup()

        // Configure popover
        popover.contentSize = NSSize(width: 350, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environment(appState)
        )

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "safari", accessibilityDescription: "TabBridge")
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        showMainWindow()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let isVisible = NSApp.windows.first(where: { $0.title == "TabBridge" })?.isVisible ?? false
        let windowItem = NSMenuItem(
            title: isVisible ? "Hide Main Window" : "Show Main Window",
            action: #selector(toggleMainWindow),
            keyEquivalent: ""
        )
        menu.addItem(windowItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit TabBridge", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "TabBridge" }),
           window.isVisible {
            window.orderOut(nil)
        } else {
            showMainWindow()
        }
    }

    func showMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "TabBridge" }) {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
