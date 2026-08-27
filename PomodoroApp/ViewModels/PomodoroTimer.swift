import Foundation
import Observation

@MainActor
@Observable
final class PomodoroTimer {
    private(set) var preferences: PomodoroPreferences
    private(set) var session: TimerSession

    private let storage: AppStorage
    @ObservationIgnored
    private var synchronizationTask: Task<Void, Never>?

    init(storage: AppStorage = AppStorage()) {
        self.storage = storage
        let storedPreferences = storage.loadPreferences()
        preferences = storedPreferences
        session = storage.loadSession() ?? .fresh(using: storedPreferences)
        normalizeSession()
        reconcile(at: Date(), givesFeedback: false)
    }

    var canSkip: Bool { session.status != .ready || session.interval != .work || session.workNumber != 1 }

    func startOrResume() {
        let now = Date()
        switch session.status {
        case .ready:
            session.startedAt = now
            session.endsAt = now.addingTimeInterval(session.pausedRemaining)
            session.status = .running
        case .paused:
            let elapsed = max(0, session.totalDuration - session.pausedRemaining)
            session.startedAt = now.addingTimeInterval(-elapsed)
            session.endsAt = now.addingTimeInterval(session.pausedRemaining)
            session.status = .running
        case .running:
            return
        }
        HapticManager.impact()
        persistAndSynchronize(requestsNotificationPermission: true)
    }

    func pause() {
        guard session.status == .running else { return }
        session.pausedRemaining = session.remaining(at: Date())
        session.endsAt = nil
        session.status = .paused
        HapticManager.selection()
        persistAndSynchronize()
    }

    func skip() {
        let shouldStart = session.status == .running || preferences.automaticallyStartNextInterval
        advance(at: Date(), startsNextInterval: shouldStart)
        HapticManager.selection()
        persistAndSynchronize(requestsNotificationPermission: shouldStart)
    }

    func reset() {
        session = .fresh(using: preferences)
        HapticManager.impact()
        persistAndSynchronize()
    }

    func tick() {
        reconcile(at: Date(), givesFeedback: true)
    }

    func sceneBecameActive() {
        reconcile(at: Date(), givesFeedback: false)
        persistAndSynchronize()
    }

    func updatePreferences(_ change: (inout PomodoroPreferences) -> Void) {
        change(&preferences)
        preferences.workMinutes = min(120, max(1, preferences.workMinutes))
        preferences.shortBreakMinutes = min(60, max(1, preferences.shortBreakMinutes))
        preferences.longBreakMinutes = min(90, max(1, preferences.longBreakMinutes))
        preferences.workIntervalsBeforeLongBreak = min(8, max(2, preferences.workIntervalsBeforeLongBreak))

        if session.status == .ready {
            let duration = preferences.duration(for: session.interval)
            session.totalDuration = duration
            session.pausedRemaining = duration
        }
        session.workNumber = min(session.workNumber, preferences.workIntervalsBeforeLongBreak)
        storage.save(preferences)
        persistAndSynchronize()
    }

    private func reconcile(at now: Date, givesFeedback: Bool) {
        guard session.status == .running, let end = session.endsAt, now >= end else { return }

        var completedAnInterval = false
        var transitionCount = 0

        while session.status == .running,
              let currentEnd = session.endsAt,
              now >= currentEnd,
              transitionCount < 128 {
            completedAnInterval = true
            advance(at: currentEnd, startsNextInterval: preferences.automaticallyStartNextInterval)
            transitionCount += 1
        }

        if transitionCount == 128, session.status == .running {
            session.startedAt = now
            session.endsAt = now.addingTimeInterval(session.totalDuration)
        }

        if completedAnInterval {
            if givesFeedback { HapticManager.intervalCompleted() }
            persistAndSynchronize()
        }
    }

    private func advance(at date: Date, startsNextInterval: Bool) {
        let next: (PomodoroIntervalKind, Int) = switch session.interval {
        case .work:
            session.workNumber >= preferences.workIntervalsBeforeLongBreak
                ? (.longBreak, session.workNumber)
                : (.shortBreak, session.workNumber)
        case .shortBreak:
            (.work, min(preferences.workIntervalsBeforeLongBreak, session.workNumber + 1))
        case .longBreak:
            (.work, 1)
        }

        session.interval = next.0
        session.workNumber = next.1
        session.totalDuration = preferences.duration(for: next.0)
        session.pausedRemaining = session.totalDuration

        if startsNextInterval {
            session.startedAt = date
            session.endsAt = date.addingTimeInterval(session.totalDuration)
            session.status = .running
        } else {
            session.startedAt = nil
            session.endsAt = nil
            session.status = .ready
        }
    }

    private func normalizeSession() {
        session.workNumber = min(
            max(1, session.workNumber),
            preferences.workIntervalsBeforeLongBreak
        )
        guard session.totalDuration > 0, session.pausedRemaining >= 0 else {
            session = .fresh(using: preferences)
            return
        }
        if session.status == .running, session.endsAt == nil {
            session = .fresh(using: preferences)
        }
    }

    private func persistAndSynchronize(requestsNotificationPermission: Bool = false) {
        storage.save(session)
        let snapshot = session
        let currentPreferences = preferences

        synchronizationTask?.cancel()
        synchronizationTask = Task {
            if requestsNotificationPermission, currentPreferences.notificationsEnabled {
                _ = await NotificationManager.shared.requestAuthorization()
            }
            guard !Task.isCancelled else { return }
            await NotificationManager.shared.schedule(for: snapshot, preferences: currentPreferences)
            guard !Task.isCancelled else { return }
            await LiveActivityManager.shared.synchronize(session: snapshot, preferences: currentPreferences)
        }
    }
}
