import Foundation
import SwiftUI

struct TimerHeroView: View {
    let session: TimerSession
    let date: Date
    let cycleTarget: Int

    private var progress: Double { session.progress(at: date) }

    var body: some View {
        VStack(spacing: 24) {
            Text(Self.formatted(session.remaining(at: date)))
                .font(.system(size: 104, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.62)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                HStack(spacing: 9) {
                    Image(systemName: session.interval.systemImage)
                        .foregroundStyle(.orange)
                        .symbolRenderingMode(.hierarchical)

                    Text(session.interval.title)
                        .foregroundStyle(.white)

                    if session.status == .paused {
                        Text("Paused")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.14), in: .capsule)
                    }
                }
                .font(.title3.weight(.semibold))

                ProgressCapsule(progress: progress)
                    .frame(maxWidth: 280)

                CycleIndicator(current: session.workNumber, total: cycleTarget)
            }
        }
        .animation(.snappy(duration: 0.35), value: session.interval)
        .animation(.snappy(duration: 0.3), value: session.status)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.interval.title), time remaining")
        .accessibilityValue(Self.spoken(session.remaining(at: date)))
    }

    static func formatted(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(interval)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private static func spoken(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(interval)))
        return "\(seconds / 60) minutes, \(seconds % 60) seconds"
    }
}

struct HoldToStopControl: View {
    let interval: PomodoroIntervalKind
    let action: () -> Void

    private static let holdDuration = 1.2

    @State private var fillProgress = 0.0
    @State private var completed = false

    var body: some View {
        VStack(spacing: 13) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))

                    Capsule()
                        .fill(.orange)
                        .frame(width: proxy.size.width * fillProgress)
                }
            }
            .frame(height: 6)

            Label("Hold to Stop \(interval.shortTitle)", systemImage: "hand.tap.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.64))
        }
        .frame(maxWidth: 280)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(.rect)
        .onLongPressGesture(
            minimumDuration: Self.holdDuration,
            maximumDistance: 44,
            perform: {
                completed = true
                action()
                fillProgress = 0
            },
            onPressingChanged: { isPressing in
                if isPressing {
                    completed = false
                    fillProgress = 0
                    HapticManager.selection()
                    withAnimation(.linear(duration: Self.holdDuration)) {
                        fillProgress = 1
                    }
                } else if !completed {
                    withAnimation(.snappy(duration: 0.25)) {
                        fillProgress = 0
                    }
                }
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hold to stop \(interval.shortTitle.lowercased())")
        .accessibilityHint("Use Reset in the actions menu with VoiceOver.")
        .accessibilityAddTraits(.isButton)
    }
}

private struct ProgressCapsule: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.1))

                Capsule()
                    .fill(.orange)
                    .frame(width: proxy.size.width * min(1, max(0, progress)))
            }
        }
        .frame(height: 5)
        .animation(.smooth(duration: 0.45), value: progress)
        .accessibilityHidden(true)
    }
}

private extension PomodoroIntervalKind {
    var shortTitle: String {
        switch self {
        case .work: "Focus"
        case .shortBreak, .longBreak: "Break"
        }
    }
}
