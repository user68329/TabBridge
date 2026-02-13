import AppKit

struct BrowserInfo: Identifiable, Hashable {
    let id: String      // bundle identifier
    let name: String
    let icon: NSImage
    let path: URL
    let isDefault: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BrowserInfo, rhs: BrowserInfo) -> Bool {
        lhs.id == rhs.id
    }
}

final class BrowserService {
    private static let knownBrowserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "company.thebrowser.Browser",       // Arc
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera",
        "com.kagi.kagimacOS",               // Orion
        "org.chromium.Chromium",
        "com.nickvision.Midori",
        "com.nickvision.Ephemeral",
        "com.nickvision.Eolie",
        "com.nickvision.Tangram",
        "com.nickvision.WebApps",
        "io.sigmaos.sigmaos.macos",
        "com.nickvision.Oku",
        "net.waterfox.waterfox",
        "com.nickvision.Librehunt",
        "com.nickvision.Tangram",
        "com.nickvision.Valere",
    ]

    func detectBrowsers() -> [BrowserInfo] {
        let testURL = URL(string: "https://example.com")!

        let defaultBrowserURL = NSWorkspace.shared.urlForApplication(toOpen: testURL)
        let defaultBundleID = defaultBrowserURL.flatMap { Bundle(url: $0)?.bundleIdentifier }

        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: testURL)

        var browsers: [BrowserInfo] = []
        for appURL in appURLs {
            guard let bundle = Bundle(url: appURL),
                  let bundleID = bundle.bundleIdentifier,
                  Self.knownBrowserBundleIDs.contains(bundleID) else { continue }

            let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent

            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 20, height: 20)

            let isDefault = bundleID == defaultBundleID

            browsers.append(BrowserInfo(
                id: bundleID,
                name: name,
                icon: icon,
                path: appURL,
                isDefault: isDefault
            ))
        }

        browsers.sort { a, b in
            if a.isDefault != b.isDefault { return a.isDefault }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }

        return browsers
    }
}
