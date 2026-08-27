import ActivityKit
import AppIntents
import Foundation
import SwiftUI
import WidgetKit

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            LockScreenActivityView(context: context)
                .activityBackgroundTint(
                    Color(red: 0.031, green: 0.039, blue: 0.063).opacity(0.96)
                )
                .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        SessionTitleView(state: context.state, font: .subheadline)

                        RemainingTimeView(
                            state: context.state,
                            font: .system(size: 30, weight: .semibold, design: .rounded)
                        )
                        .foregroundStyle(.white)
                        .frame(width: 112, alignment: .leading)
                    }
                    .frame(width: 142, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    EndActivityButton(sessionID: context.attributes.sessionID)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 7) {
                        ActivityProgressView(state: context.state)

                        CyclePositionView(
                            current: context.state.workNumber,
                            total: context.state.workTarget
                        )
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.58))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 4)
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
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    SessionTitleView(state: context.state, font: .headline)

                    CyclePositionView(
                        current: context.state.workNumber,
                        total: context.state.workTarget
                    )
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.64))
                }

                Spacer(minLength: 4)

                RemainingTimeView(
                    state: context.state,
                    font: .system(size: 34, weight: .semibold, design: .rounded)
                )
                .foregroundStyle(.white)
                .frame(width: 102, alignment: .trailing)

                EndActivityButton(sessionID: context.attributes.sessionID)
            }

            ActivityProgressView(state: context.state)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .contain)
    }
}

private struct SessionTitleView: View {
    let state: PomodoroActivityAttributes.ContentState
    let font: Font

    var body: some View {
        HStack(spacing: 7) {
            PhaseGlyph(interval: state.interval, font: font)

            Text(state.interval.title)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            if state.status == .paused {
                Image(systemName: "pause.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Paused")
            }
        }
        .font(font.weight(.semibold))
    }
}

private struct EndActivityButton: View {
    let sessionID: UUID

    var body: some View {
        Button(intent: EndPomodoroIntent(sessionID: sessionID)) {
            Text("End")
                .font(.subheadline.weight(.bold))
                .frame(width: 58, height: 36)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(.orange.opacity(0.22))
        .foregroundStyle(.orange)
        .accessibilityLabel("End Pomodoro session")
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
        .progressViewStyle(.linear)
        .labelsHidden()
        .accessibilityLabel("Interval progress")
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
