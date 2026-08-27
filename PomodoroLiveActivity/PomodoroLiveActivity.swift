import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            LockScreenActivityView(context: context)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(
                        context.state.interval.title,
                        systemImage: context.state.interval.systemImage
                    )
                    .font(.headline)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.workNumber) of \(context.state.workTarget)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 10) {
                        RemainingTimeView(state: context.state, font: .system(size: 38, weight: .light, design: .rounded))
                        ActivityProgressView(state: context.state)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.interval.systemImage)
                    .accessibilityLabel(context.state.interval.title)
            } compactTrailing: {
                RemainingTimeView(state: context.state, font: .caption.monospacedDigit())
                    .frame(maxWidth: 48)
            } minimal: {
                Image(systemName: context.state.interval.systemImage)
                    .accessibilityLabel(context.state.interval.title)
            }
            .keylineTint(.primary)
        }
    }
}

private struct LockScreenActivityView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Label(
                    context.state.interval.title,
                    systemImage: context.state.interval.systemImage
                )
                .font(.headline)

                Spacer()

                Text("\(context.state.workNumber) of \(context.state.workTarget)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            HStack(alignment: .firstTextBaseline) {
                RemainingTimeView(
                    state: context.state,
                    font: .system(size: 42, weight: .light, design: .rounded)
                )
                Spacer()
                if context.state.status == .paused {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Paused")
                }
            }

            ActivityProgressView(state: context.state)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}

private struct RemainingTimeView: View {
    let state: PomodoroActivityAttributes.ContentState
    let font: Font

    var body: some View {
        Group {
            if state.status == .running, let endsAt = state.endsAt {
                Text(
                    timerInterval: state.startedAt...endsAt,
                    countsDown: true,
                    showsHours: false
                )
            } else {
                Text(Self.formatted(state.pausedRemaining))
            }
        }
        .font(font)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private static func formatted(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(interval)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ActivityProgressView: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.status == .running, let endsAt = state.endsAt {
                ProgressView(timerInterval: state.startedAt...endsAt, countsDown: false)
            } else {
                ProgressView(
                    value: max(0, state.totalDuration - state.pausedRemaining),
                    total: max(1, state.totalDuration)
                )
            }
        }
        .tint(.primary)
    }
}
