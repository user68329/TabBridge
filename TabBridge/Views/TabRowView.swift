import SwiftUI

struct TabRowView: View {
    let tab: Tab

    var body: some View {
        HStack(spacing: 8) {
            if tab.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(tab.displayTitle)
                    .lineLimit(1)
                    .font(.body)

                HStack(spacing: 4) {
                    Text(tab.domain)
                    if let lastViewed = tab.relativeLastViewed {
                        Text("·")
                        Text(lastViewed)
                    }
                }
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

// MARK: - Double-Click (AppKit)

/// Transparent NSView that checks clickCount on mouseDown.
/// No gesture recognizer — fires instantly on the second click
/// without delaying single-click selection.
private class DoubleClickView: NSView {
    var onDoubleClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            onDoubleClick?()
        }
    }
}

private struct DoubleClickOverlay: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> DoubleClickView {
        let view = DoubleClickView()
        view.onDoubleClick = action
        return view
    }

    func updateNSView(_ nsView: DoubleClickView, context: Context) {
        nsView.onDoubleClick = action
    }
}

extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        overlay { DoubleClickOverlay(action: action) }
    }
}
