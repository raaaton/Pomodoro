import Foundation
import SwiftUI

struct TimerProgressView: View {
    let session: TimerSession
    let date: Date

    private var progress: Double { session.progress(at: date) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 8)

            Circle()
                .trim(from: 0, to: max(0.002, progress))
                .stroke(
                    .primary,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.45), value: progress)

            Text(Self.formatted(session.remaining(at: date)))
                .font(.system(size: 62, weight: .thin, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .padding(36)
                .accessibilityLabel("Time remaining")
                .accessibilityValue(Self.spoken(session.remaining(at: date)))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
    }

    static func formatted(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(interval)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private static func spoken(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(interval)))
        let minutesPart = seconds / 60
        let secondsPart = seconds % 60
        return "\(minutesPart) minutes, \(secondsPart) seconds"
    }
}
