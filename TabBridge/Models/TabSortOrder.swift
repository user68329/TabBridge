import Foundation

enum SortDirection: String {
    case ascending
    case descending

    var label: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }

    var icon: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }

    var toggled: SortDirection {
        self == .ascending ? .descending : .ascending
    }
}

enum TabSortOrder: String, CaseIterable, Identifiable {
    case lastViewed
    case title
    case domain
    case tabPosition

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lastViewed: return "Last Viewed"
        case .title: return "Title"
        case .domain: return "Domain"
        case .tabPosition: return "Tab Position"
        }
    }

    var icon: String {
        switch self {
        case .lastViewed: return "clock"
        case .title: return "textformat"
        case .domain: return "globe"
        case .tabPosition: return "list.number"
        }
    }

    var defaultDirection: SortDirection {
        switch self {
        case .lastViewed: return .descending
        case .title: return .ascending
        case .domain: return .ascending
        case .tabPosition: return .ascending
        }
    }
}
