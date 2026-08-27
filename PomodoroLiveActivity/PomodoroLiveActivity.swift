import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            LockScreenActivityView(context: context)
                .activityBackgroundTint(.black.opacity(0.88))
                .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PhaseGlyph(interval: context.state.interval, font: .title3)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RemainingTimeView(
                        state: context.state,
                        font: .system(size: 28, weight: .semibold, design: .rounded)
                    )
                    .foregroundStyle(.white)
                    .frame(width: 88, alignment: .trailing)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 7) {
                        HStack(spacing: 8) {
                            Text(context.state.interval.title)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            CyclePositionView(
                                current: context.state.workNumber,
                                total: context.state.workTarget
                            )
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))

                        ActivityProgressView(state: context.state)
                    }
                    .padding(.top, 2)
                }
            } compactLeading: {
                PhaseGlyph(interval: context.state.interval, font: .body)
            } compactTrailing: {
                RemainingTimeView(
                    state: context.state,
                    font: .caption2.weight(.semibold).monospacedDigit()
                )
                .foregroundStyle(.white)
                .frame(width: 42, alignment: .trailing)
            } minimal: {
                PhaseGlyph(interval: context.state.interval, font: .body)
            }
            .keylineTint(.orange)
        }
    }
}

private struct LockScreenActivityView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        PhaseGlyph(interval: context.state.interval, font: .headline)

                        Text(context.state.interval.title)
                            .foregroundStyle(.white)
                    }
                    .font(.headline.weight(.semibold))

                    CyclePositionView(
                        current: context.state.workNumber,
                        total: context.state.workTarget
                    )
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.64))
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    if context.state.status == .paused {
                        Image(systemName: "pause.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.64))
                            .accessibilityLabel("Paused")
                    }

                    RemainingTimeView(
                        state: context.state,
                        font: .system(size: 36, weight: .semibold, design: .rounded)
                    )
                    .foregroundStyle(.white)
                    .frame(width: 108, alignment: .trailing)
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
            if let range = runningRange {
                Text(
                    timerInterval: range,
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

    private var runningRange: ClosedRange<Date>? {
        guard state.status == .running,
              let endsAt = state.endsAt,
              endsAt > state.startedAt else {
            return nil
        }
        return state.startedAt...endsAt
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
            if let range = runningRange {
                ProgressView(timerInterval: range, countsDown: false)
            } else {
                ProgressView(
                    value: max(0, state.totalDuration - state.pausedRemaining),
                    total: max(1, state.totalDuration)
                )
            }
        }
        .tint(.orange)
    }

    private var runningRange: ClosedRange<Date>? {
        guard state.status == .running,
              let endsAt = state.endsAt,
              endsAt > state.startedAt else {
            return nil
        }
        return state.startedAt...endsAt
    }
}

private struct PhaseGlyph: View {
    let interval: PomodoroIntervalKind
    let font: Font

    var body: some View {
        Image(systemName: interval.systemImage)
            .font(font)
            .foregroundStyle(.orange)
            .symbolRenderingMode(.hierarchical)
            .accessibilityLabel(interval.title)
    }
}

private struct CyclePositionView: View {
    let current: Int
    let total: Int

    var body: some View {
        Text("Interval \(current) of \(total)")
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityLabel("Focus interval \(current) of \(total)")
    }
}
