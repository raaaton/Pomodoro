import SwiftUI

struct CycleIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { position in
                Capsule()
                    .fill(fillStyle(for: position))
                    .frame(width: position == current ? 18 : 6, height: 6)
            }
        }
        .animation(.snappy(duration: 0.35), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus interval \(current) of \(total)")
    }

    private func fillStyle(for position: Int) -> Color {
        if position == current { return .orange }
        if position < current { return .orange.opacity(0.42) }
        return .secondary.opacity(0.2)
    }
}
