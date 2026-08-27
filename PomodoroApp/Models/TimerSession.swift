import Foundation

struct TimerSession: Codable, Equatable, Sendable {
    enum Status: String, Codable, Sendable {
        case ready
        case running
        case paused
    }

    var id: UUID
    var interval: PomodoroIntervalKind
    var status: Status
    var workNumber: Int
    var startedAt: Date?
    var endsAt: Date?
    var pausedRemaining: TimeInterval
    var totalDuration: TimeInterval

    static func fresh(using preferences: PomodoroPreferences) -> TimerSession {
        TimerSession(
            id: UUID(),
            interval: .work,
            status: .ready,
            workNumber: 1,
            startedAt: nil,
            endsAt: nil,
            pausedRemaining: preferences.duration(for: .work),
            totalDuration: preferences.duration(for: .work)
        )
    }

    func remaining(at date: Date) -> TimeInterval {
        switch status {
        case .ready, .paused:
            return max(0, pausedRemaining)
        case .running:
            return max(0, endsAt?.timeIntervalSince(date) ?? 0)
        }
    }

    func progress(at date: Date) -> Double {
        guard totalDuration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining(at: date) / totalDuration))
    }
}
