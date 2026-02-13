import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TabBridge")
                    .font(.headline)

                Spacer()

                Button(action: {
                    if let window = NSApp.windows.first(where: { $0.title == "TabBridge" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }) {
                    Image(systemName: "macwindow")
                }
                .buttonStyle(.borderless)
                .help("Open main window")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if !state.hasAccess {
                noAccessView
            } else if state.allTabs.isEmpty {
                emptyView
            } else {
                tabListView
            }

            Divider()

            // Footer
            HStack {
                Text("\(state.totalTabCount) tabs across \(state.devices.count) devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: { state.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Refresh iCloud tabs")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 350)
    }

    private var noAccessView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Full Disk Access required")
                .font(.callout)
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.callout)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "safari")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No iCloud tabs found")
                .font(.callout)
            Text("Open tabs in Safari on your other devices")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    private var tabListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                let groups = state.filteredTabsByDevice
                ForEach(groups, id: \.0.id) { device, tabs in
                    DeviceSectionView(
                        device: device,
                        tabs: tabs,
                        onOpenTab: { state.openTab($0) },
                        onOpenAll: { state.openAllTabs(for: device) }
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)

                    if device.id != groups.last?.0.id {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }
}
