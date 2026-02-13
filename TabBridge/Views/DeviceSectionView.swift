import SwiftUI

struct DeviceSectionView: View {
    let device: Device
    let tabs: [Tab]
    let onOpenTab: (Tab) -> Void
    let onOpenAll: () -> Void

    var body: some View {
        Section {
            ForEach(tabs) { tab in
                TabRowView(tab: tab)
                    .contentShape(Rectangle())
                    .onTapGesture { onOpenTab(tab) }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: device.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

                Button("Open All") {
                    onOpenAll()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.tint)
                .help("Open all tabs from this device")
            }
        }
    }
}
