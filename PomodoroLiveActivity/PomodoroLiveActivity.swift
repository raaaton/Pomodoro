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
                    HStack(spacing: 6) {
                        Image(systemName: context.state.interval.systemImage)
                            .symbolRenderingMode(.hierarchical)
                        Text(context.state.interval.title)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RemainingTimeView(
                        state: context.state,
                        font: .system(size: 28, weight: .semibold, design: .rounded)
                    )
                    .fixedSize(horizontal: true, vertical: false)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ActivityProgressView(state: context.state)

                        HStack(spacing: 8) {
                            Text("Interval \(context.state.workNumber) of \(context.state.workTarget)")
                                .monospacedDigit()
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)

                            Spacer(minLength: 8)

                            if context.state.status == .paused {
                                Label("Paused", systemImage: "pause.fill")
                                    .lineLimit(1)
                            }
                        }
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 3)
                }
            } compactLeading: {
                Image(systemName: context.state.interval.systemImage)
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel(context.state.interval.title)
            } compactTrailing: {
                RemainingTimeView(
                    state: context.state,
                    font: .caption2.weight(.semibold).monospacedDigit()
                )
                .fixedSize(horizontal: true, vertical: false)
            } minimal: {
                Image(systemName: context.state.interval.systemImage)
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel(context.state.interval.title)
            }
            .keylineTint(.orange)
        }
    }
}

private struct LockScreenActivityView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Image(systemName: context.state.interval.systemImage)
                            .foregroundStyle(.orange)
                            .symbolRenderingMode(.hierarchical)

                        Text(context.state.interval.title)
                            .foregroundStyle(.primary)
                    }
                    .font(.headline.weight(.semibold))

                    Text("Interval \(context.state.workNumber) of \(context.state.workTarget)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    if context.state.status == .paused {
                        Image(systemName: "pause.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Paused")
                    }

                    RemainingTimeView(
                        state: context.state,
                        font: .system(size: 38, weight: .semibold, design: .rounded)
                    )
                    .fixedSize(horizontal: true, vertical: false)
                }
            }

            ActivityProgressView(state: context.state)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        .tint(.orange)
    }
}
