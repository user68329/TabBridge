import AppKit

final class URLOpener {
    func open(url: URL, in browser: BrowserInfo? = nil) {
        if let browser {
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: browser.path,
                configuration: NSWorkspace.OpenConfiguration()
            )
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    func open(urls: [URL], in browser: BrowserInfo? = nil) {
        guard !urls.isEmpty else { return }
        if let browser {
            NSWorkspace.shared.open(
                urls,
                withApplicationAt: browser.path,
                configuration: NSWorkspace.OpenConfiguration()
            )
        } else {
            for url in urls {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
