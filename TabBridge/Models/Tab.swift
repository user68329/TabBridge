import Foundation

struct Tab: Identifiable, Hashable {
    let id: String          // tab_uuid
    let deviceID: String    // device_uuid
    let title: String?
    let url: URL
    let isPinned: Bool
    let positionSortValue: Int?
    let lastViewedTime: Date?

    var displayTitle: String {
        if let title, !title.isEmpty {
            return title
        }
        return url.host ?? url.absoluteString
    }

    var domain: String {
        url.host ?? url.absoluteString
    }

    var relativeLastViewed: String? {
        guard let lastViewedTime else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastViewedTime, relativeTo: Date())
    }

    var favicon: URL? {
        guard let scheme = url.scheme, let host = url.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?sz=32&domain=\(host)")
    }
}
