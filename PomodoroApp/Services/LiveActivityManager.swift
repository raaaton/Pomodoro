import ActivityKit
import Foundation

actor LiveActivityManager {
    static let shared = LiveActivityManager()

    func synchronize(session: TimerSession, preferences: PomodoroPreferences) async {
        switch session.status {
        case .ready:
            await endAll()
        case .running, .paused:
            let state = contentState(for: session, preferences: preferences)
            let content = ActivityContent(
                state: state,
                staleDate: session.endsAt,
                relevanceScore: 100
            )

            let activities = Activity<PomodoroActivityAttributes>.activities

            if let activity = activities.first(where: {
                $0.attributes.sessionID == session.id
            }) {
                await activity.update(content)

                for staleActivity in activities where staleActivity.id != activity.id {
                    await staleActivity.end(nil, dismissalPolicy: .immediate)
                }
            } else {
                await endAll()
                guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
                let attributes = PomodoroActivityAttributes(sessionID: session.id)
                do {
                    _ = try Activity.request(
                        attributes: attributes,
                        content: content,
                        pushType: nil
                    )
                } catch {
                    print("Unable to start Pomodoro Live Activity: \(error)")
                }
            }
        }
    }

    func endAll() async {
        for activity in Activity<PomodoroActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func contentState(
        for session: TimerSession,
        preferences: PomodoroPreferences
    ) -> PomodoroActivityAttributes.ContentState {
        PomodoroActivityAttributes.ContentState(
            interval: session.interval,
            status: session.status == .running ? .running : .paused,
            startedAt: session.startedAt ?? Date(),
            endsAt: session.endsAt,
            pausedRemaining: session.pausedRemaining,
            totalDuration: session.totalDuration,
            workNumber: session.workNumber,
            workTarget: preferences.workIntervalsBeforeLongBreak
        )
    }
}
