import ActivityKit
import Foundation

enum PomodoroIntervalKind: String, Codable, CaseIterable, Hashable, Sendable {
    case work
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .work: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }

    var systemImage: String {
        switch self {
        case .work: "book.closed.fill"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "moon.zzz.fill"
        }
    }
}

struct PomodoroActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Status: String, Codable, Hashable {
            case running
            case paused
        }

        var interval: PomodoroIntervalKind
        var status: Status
        var startedAt: Date
        var endsAt: Date?
        var pausedRemaining: TimeInterval
        var totalDuration: TimeInterval
        var workNumber: Int
        var workTarget: Int
    }

    var sessionID: UUID
}
