import SwiftUI

struct PermissionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Full Disk Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("TabBridge needs Full Disk Access to read your iCloud Tabs from Safari's database.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 300)

            VStack(alignment: .leading, spacing: 8) {
                Label("Open System Settings", systemImage: "1.circle.fill")
                Label("Go to Privacy & Security > Full Disk Access", systemImage: "2.circle.fill")
                Label("Enable TabBridge", systemImage: "3.circle.fill")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .help("Open Privacy & Security settings")

                Button("Retry") {
                    state.checkAccess()
                    if state.hasAccess {
                        state.refresh()
                        state.startMonitoring()
                    }
                }
                .help("Check Full Disk Access again")
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
