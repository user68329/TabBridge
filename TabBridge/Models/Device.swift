import Foundation

struct Device: Identifiable, Hashable {
    let id: String          // device_uuid
    let name: String        // device_name
    let lastModified: Date  // Core Data timestamp

    var icon: String {
        let lower = name.lowercased()
        if lower.contains("iphone") || lower.contains("phone") || lower.contains("pro max") {
            return "iphone"
        } else if lower.contains("ipad") || lower.contains("pad") {
            return "ipad"
        } else if lower.contains("mini") {
            return "desktopcomputer"
        } else if lower.contains("macbook") || lower.contains("mbp") || lower.contains("mba") {
            return "laptopcomputer"
        } else if lower.contains("mac") || lower.contains("imac") {
            return "desktopcomputer"
        } else {
            return "display"
        }
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
}
