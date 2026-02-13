import SwiftUI

@Observable
final class AppState {
    // Data
    var devices: [Device] = []
    var allTabs: [Tab] = []
    var tabsByDevice: [String: [Tab]] = [:]
    var browsers: [BrowserInfo] = []

    // Selection
    var selectedTabIDs: Set<String> = []
    var selectedBrowserID: String?

    // UI State
    var searchText: String = ""
    var hasAccess: Bool = false
    var errorMessage: String?
    var filterDeviceIDs: Set<String> = []
    var previewTab: Tab? = nil
    var tabSortOrder: TabSortOrder = {
        if let raw = UserDefaults.standard.string(forKey: "tabSortOrder"),
           let order = TabSortOrder(rawValue: raw) {
            return order
        }
        return .tabPosition
    }()
    var sortDirection: SortDirection = {
        let order: TabSortOrder = {
            if let raw = UserDefaults.standard.string(forKey: "tabSortOrder"),
               let o = TabSortOrder(rawValue: raw) { return o }
            return .tabPosition
        }()
        if let raw = UserDefaults.standard.string(forKey: "sortDirection"),
           let dir = SortDirection(rawValue: raw) {
            return dir
        }
        return order.defaultDirection
    }()

    // Setup guard
    private(set) var isSetUp = false

    // Services
    private let database = CloudTabsDatabase()
    private var monitor: DatabaseMonitor?
    private let browserService = BrowserService()
    let urlOpener = URLOpener()

    var selectedBrowser: BrowserInfo? {
        browsers.first { $0.id == selectedBrowserID }
    }

    var filteredTabsByDevice: [(Device, [Tab])] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        return devices.compactMap { device in
            if !filterDeviceIDs.isEmpty && !filterDeviceIDs.contains(device.id) {
                return nil
            }
            let tabs = tabsByDevice[device.id] ?? []
            if query.isEmpty {
                return tabs.isEmpty ? nil : (device, sortTabs(tabs))
            }
            let filtered = tabs.filter { tab in
                tab.displayTitle.localizedCaseInsensitiveContains(query) ||
                tab.url.absoluteString.localizedCaseInsensitiveContains(query) ||
                device.name.localizedCaseInsensitiveContains(query)
            }
            return filtered.isEmpty ? nil : (device, sortTabs(filtered))
        }
    }

    private func sortTabs(_ tabs: [Tab]) -> [Tab] {
        let reversed = sortDirection != tabSortOrder.defaultDirection
        return tabs.sorted { a, b in
            // Pinned tabs always first
            if a.isPinned != b.isPinned { return a.isPinned }

            let result: Bool
            switch tabSortOrder {
            case .lastViewed:
                switch (a.lastViewedTime, b.lastViewedTime) {
                case (let at?, let bt?): result = at > bt
                case (_?, nil): result = true
                case (nil, _?): result = false
                case (nil, nil): result = false
                }
            case .title:
                result = a.displayTitle.localizedCaseInsensitiveCompare(b.displayTitle) == .orderedAscending
            case .domain:
                let domainCmp = a.domain.localizedCaseInsensitiveCompare(b.domain)
                if domainCmp != .orderedSame {
                    result = domainCmp == .orderedAscending
                } else {
                    result = a.displayTitle.localizedCaseInsensitiveCompare(b.displayTitle) == .orderedAscending
                }
            case .tabPosition:
                switch (a.positionSortValue, b.positionSortValue) {
                case (let ap?, let bp?): result = ap < bp
                case (_?, nil): result = true
                case (nil, _?): result = false
                case (nil, nil): result = false
                }
            }
            return reversed ? !result : result
        }
    }

    var selectedTabs: [Tab] {
        allTabs.filter { selectedTabIDs.contains($0.id) }
    }

    var totalTabCount: Int {
        allTabs.count
    }

    // MARK: - Initialization

    func setup() {
        guard !isSetUp else { return }
        isSetUp = true
        checkAccess()
        detectBrowsers()
        if hasAccess {
            refresh()
            startMonitoring()
        }
    }

    func checkAccess() {
        hasAccess = database.isAccessible()
    }

    func detectBrowsers() {
        browsers = browserService.detectBrowsers()
        if selectedBrowserID == nil {
            selectedBrowserID = browsers.first(where: { $0.isDefault })?.id ?? browsers.first?.id
        }
    }

    func setTabSortOrder(_ order: TabSortOrder) {
        tabSortOrder = order
        UserDefaults.standard.set(order.rawValue, forKey: "tabSortOrder")
        setSortDirection(order.defaultDirection)
    }

    func setSortDirection(_ direction: SortDirection) {
        sortDirection = direction
        UserDefaults.standard.set(direction.rawValue, forKey: "sortDirection")
    }

    // MARK: - Data Refresh

    func refresh() {
        do {
            let (fetchedDevices, fetchedTabs) = try database.fetchDevicesAndTabs()
            devices = fetchedDevices
            allTabs = fetchedTabs

            var grouped: [String: [Tab]] = [:]
            for tab in fetchedTabs {
                grouped[tab.deviceID, default: []].append(tab)
            }
            tabsByDevice = grouped
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        monitor = DatabaseMonitor { [weak self] in
            self?.refresh()
        }
        monitor?.start()
    }

    func stopMonitoring() {
        monitor?.stop()
        monitor = nil
    }

    // MARK: - Actions

    func openTab(_ tab: Tab) {
        urlOpener.open(url: tab.url, in: selectedBrowser)
    }

    func openTabs(_ tabs: [Tab]) {
        let urls = tabs.map(\.url)
        urlOpener.open(urls: urls, in: selectedBrowser)
    }

    func openAllTabs(for device: Device) {
        let tabs = tabsByDevice[device.id] ?? []
        openTabs(tabs)
    }

    func openSelectedTabs() {
        openTabs(selectedTabs)
    }

}
