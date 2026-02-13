import SwiftUI

@main
struct TabBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Window("TabBridge", id: "main") {
            MainWindowView()
                .environment(delegate.appState)
        }
        .defaultSize(width: 700, height: 500)
    }
}
