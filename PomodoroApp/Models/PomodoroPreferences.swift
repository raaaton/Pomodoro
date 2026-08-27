import Foundation

struct PomodoroPreferences: Codable, Equatable, Sendable {
    var workMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    var workIntervalsBeforeLongBreak = 4
    var automaticallyStartNextInterval = false
    var notificationsEnabled = true

    static let `default` = PomodoroPreferences()

    func duration(for interval: PomodoroIntervalKind) -> TimeInterval {
        let minutes = switch interval {
        case .work: workMinutes
        case .shortBreak: shortBreakMinutes
        case .longBreak: longBreakMinutes
        }
        return TimeInterval(minutes * 60)
    }
}
