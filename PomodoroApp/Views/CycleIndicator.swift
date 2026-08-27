import SwiftUI

struct CycleIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                ForEach(1...total, id: \.self) { position in
                    Circle()
                        .fill(position <= current ? AnyShapeStyle(.primary) : AnyShapeStyle(.quaternary))
                        .frame(width: 6, height: 6)
                }
            }
            Text("\(current) of \(total)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus interval \(current) of \(total)")
    }
}
