import Foundation
import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "pomodoro.interval."

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func cancelScheduledIntervals() async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func schedule(for session: TimerSession, preferences: PomodoroPreferences) async {
        await cancelScheduledIntervals()

        guard
            preferences.notificationsEnabled,
            session.status == .running,
            let firstEnd = session.endsAt,
            await authorizationStatus() == .authorized
        else { return }

        var interval = session.interval
        var workNumber = session.workNumber
        var endDate = firstEnd
        let notificationCount = preferences.automaticallyStartNextInterval ? 32 : 1

        for index in 0..<notificationCount {
            let next = Self.nextInterval(
                after: interval,
                workNumber: workNumber,
                target: preferences.workIntervalsBeforeLongBreak
            )
            let content = UNMutableNotificationContent()
            content.title = Self.completedTitle(for: interval)
            content.body = "\(next.interval.title) is ready."
            content.sound = .default
            content.threadIdentifier = "pomodoro"

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, endDate.timeIntervalSinceNow),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(session.id.uuidString).\(index)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)

            guard preferences.automaticallyStartNextInterval else { break }
            interval = next.interval
            workNumber = next.workNumber
            endDate = endDate.addingTimeInterval(preferences.duration(for: interval))
        }
    }

    nonisolated private static func completedTitle(for interval: PomodoroIntervalKind) -> String {
        switch interval {
        case .work: "Focus complete"
        case .shortBreak, .longBreak: "Break complete"
        }
    }

    nonisolated private static func nextInterval(
        after interval: PomodoroIntervalKind,
        workNumber: Int,
        target: Int
    ) -> (interval: PomodoroIntervalKind, workNumber: Int) {
        switch interval {
        case .work:
            return workNumber >= target ? (.longBreak, workNumber) : (.shortBreak, workNumber)
        case .shortBreak:
            return (.work, min(target, workNumber + 1))
        case .longBreak:
            return (.work, 1)
        }
    }
}
