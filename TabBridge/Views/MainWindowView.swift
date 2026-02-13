import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        Group {
            if !state.hasAccess {
                PermissionView()
            } else if state.allTabs.isEmpty && state.errorMessage == nil {
                emptyStateView
            } else {
                tabListView
            }
        }
        .searchable(text: $state.searchText, prompt: "Search tabs...")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !state.selectedTabIDs.isEmpty {
                    Button(action: { state.openSelectedTabs() }) {
                        Label("Open Selected (\(state.selectedTabIDs.count))", systemImage: "arrow.up.right.square")
                    }
                    .help("Open selected tabs in browser")

                }

                Button(action: { state.refresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh iCloud tabs")

                sortOrderMenu

                deviceFilterMenu
            }
        }
        .sheet(item: $state.previewTab) { tab in
            previewSheet(for: tab)
        }
        .onKeyPress(.space) {
            togglePreview()
            return .handled
        }
        .onKeyPress(.return) {
            if !state.selectedTabIDs.isEmpty {
                state.openSelectedTabs()
                return .handled
            }
            return .ignored
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            state.setup()
            NSApp.setActivationPolicy(.regular)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Sort Order

    private var sortOrderMenu: some View {
        Menu {
            ForEach(TabSortOrder.allCases) { order in
                Button {
                    state.setTabSortOrder(order)
                } label: {
                    if state.tabSortOrder == order {
                        Label(order.label, systemImage: "checkmark")
                    } else {
                        Text(order.label)
                    }
                }
            }

            Divider()

            Button {
                state.setSortDirection(state.sortDirection.toggled)
            } label: {
                Label(state.sortDirection.label, systemImage: state.sortDirection.icon)
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .help("Sort tabs")
    }

    // MARK: - Device Filter

    private var deviceFilterMenu: some View {
        Menu {
            Button {
                state.filterDeviceIDs = []
            } label: {
                if state.filterDeviceIDs.isEmpty {
                    Label("All Devices", systemImage: "checkmark")
                } else {
                    Text("All Devices")
                }
            }

            Divider()

            ForEach(state.devices) { device in
                Button {
                    if state.filterDeviceIDs.contains(device.id) {
                        state.filterDeviceIDs.remove(device.id)
                    } else {
                        state.filterDeviceIDs.insert(device.id)
                    }
                } label: {
                    if state.filterDeviceIDs.contains(device.id) {
                        Label(device.name, systemImage: "checkmark")
                    } else {
                        Text(device.name)
                    }
                }
            }
        } label: {
            Label(
                state.filterDeviceIDs.isEmpty ? "All Devices" : "\(state.filterDeviceIDs.count) Devices",
                systemImage: state.filterDeviceIDs.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .help("Filter by device")
    }

    // MARK: - Preview

    private func togglePreview() {
        if state.previewTab != nil {
            state.previewTab = nil
        } else if let firstID = state.selectedTabIDs.first,
                  let tab = state.allTabs.first(where: { $0.id == firstID }) {
            state.previewTab = tab
        }
    }

    private func previewSheet(for tab: Tab) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.displayTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Text(tab.domain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Open in Browser") {
                    state.openTab(tab)
                    state.previewTab = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    state.previewTab = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(12)

            Divider()

            WebPreview(url: tab.url)
        }
        .frame(width: 700, height: 500)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func tabContextMenu(tab: Tab, device: Device) -> some View {
        let selectedContainsTab = state.selectedTabIDs.contains(tab.id)
        let effectiveTabs = selectedContainsTab ? state.selectedTabs : [tab]
        let count = effectiveTabs.count
        let isMultiple = count > 1

        let browserName = state.selectedBrowser?.name ?? "Default Browser"

        Button {
            state.openTabs(effectiveTabs)
        } label: {
            Text(isMultiple ? "Open \(count) Tabs in \(browserName)" : "Open in \(browserName)")
        }

        Menu(isMultiple ? "Open \(count) Tabs in" : "Open in") {
            ForEach(state.browsers) { browser in
                Button {
                    let urls = effectiveTabs.map(\.url)
                    state.urlOpener.open(urls: urls, in: browser)
                } label: {
                    HStack(spacing: 4) {
                        Image(nsImage: browser.icon)
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(browser.name)
                    }
                }
            }
        }

        if !isMultiple {
            Divider()

            Button("Quick Look") {
                state.previewTab = tab
            }
        }

        Divider()

        Button(isMultiple ? "Copy \(count) Links" : "Copy Link") {
            let links = effectiveTabs.map(\.url.absoluteString).joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(links, forType: .string)
        }

        if !isMultiple {
            Button("Copy Title") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tab.displayTitle, forType: .string)
            }
        }

    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No iCloud Tabs", systemImage: "safari")
        } description: {
            Text("Open tabs in Safari on your other Apple devices to see them here.")
        } actions: {
            Button("Refresh") { state.refresh() }
        }
    }

    private func tabRow(tab: Tab, device: Device) -> some View {
        TabRowView(tab: tab)
            .tag(tab.id)
            .onDoubleClick { state.openTab(tab) }
            .contextMenu {
                tabContextMenu(tab: tab, device: device)
            }
    }

    private var tabListView: some View {
        List(selection: Binding(
            get: { state.selectedTabIDs },
            set: { state.selectedTabIDs = $0 }
        )) {
            if let error = state.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
            }

            let groups = state.filteredTabsByDevice
            ForEach(groups, id: \.0.id) { device, tabs in
                Section {
                    ForEach(tabs) { tab in
                        tabRow(tab: tab, device: device)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: device.icon)
                            .font(.caption)
                        Text(device.name)
                            .font(.headline)
                        Text("\(tabs.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())

                        Spacer()

                        Text(device.relativeDate)
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Button("Open All \(tabs.count)") {
                            state.openAllTabs(for: device)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .help("Open all tabs from this device")
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
