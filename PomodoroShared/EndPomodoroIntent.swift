import ActivityKit
import AppIntents
import Foundation
import UserNotifications

struct EndPomodoroIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Pomodoro Session"
    static var description = IntentDescription(
        "Stops the current Pomodoro session and returns to the first focus interval."
    )
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Session ID")
    var sessionID: String

    init() {
        sessionID = ""
    }

    init(sessionID: UUID) {
        self.sessionID = sessionID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let requestedID = UUID(uuidString: sessionID) else {
            return .result()
        }

        let storage = AppStorage()
        let preferences = storage.loadPreferences()
        var didResetCurrentSession = false

        if let storedSession = storage.loadSession(),
           let freshSession = PomodoroSessionEndPolicy.resetSession(
               storedSession,
               requestedID: requestedID,
               preferences: preferences
           ) {
            storage.save(freshSession)
            await cancelScheduledPomodoroNotifications()
            didResetCurrentSession = true
        }

        for activity in Activity<PomodoroActivityAttributes>.activities
        where activity.attributes.sessionID == requestedID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        if didResetCurrentSession {
            NotificationCenter.default.post(name: .pomodoroSessionDidChange, object: nil)
        }

        return .result()
    }

    private func cancelScheduledPomodoroNotifications() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix("pomodoro.interval.") }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

enum PomodoroSessionEndPolicy {
    static func resetSession(
        _ session: TimerSession,
        requestedID: UUID,
        preferences: PomodoroPreferences
    ) -> TimerSession? {
        guard session.id == requestedID else { return nil }
        return .fresh(using: preferences)
    }
}

extension Notification.Name {
    static let pomodoroSessionDidChange = Notification.Name(
        "com.raaaton.Pomodoro.sessionDidChange"
    )
}
