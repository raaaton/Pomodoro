import XCTest
@testable import Pomodoro

final class TimerSessionTests: XCTestCase {
    func testFreshSessionUsesFocusDuration() {
        var preferences = PomodoroPreferences.default
        preferences.workMinutes = 30

        let session = TimerSession.fresh(using: preferences)

        XCTAssertEqual(session.interval, .work)
        XCTAssertEqual(session.status, .ready)
        XCTAssertEqual(session.workNumber, 1)
        XCTAssertEqual(session.pausedRemaining, 30 * 60)
        XCTAssertEqual(session.totalDuration, 30 * 60)
    }

    func testRunningRemainingTimeUsesPersistedEndDate() {
        let now = Date(timeIntervalSince1970: 1_000)
        var session = TimerSession.fresh(using: .default)
        session.status = .running
        session.startedAt = now
        session.endsAt = now.addingTimeInterval(1_500)

        XCTAssertEqual(session.remaining(at: now.addingTimeInterval(300)), 1_200)
        XCTAssertEqual(session.progress(at: now.addingTimeInterval(300)), 0.2, accuracy: 0.0001)
    }

    func testExpiredRunningSessionNeverReportsNegativeTime() {
        let now = Date(timeIntervalSince1970: 1_000)
        var session = TimerSession.fresh(using: .default)
        session.status = .running
        session.endsAt = now.addingTimeInterval(-1)

        XCTAssertEqual(session.remaining(at: now), 0)
        XCTAssertEqual(session.progress(at: now), 1)
    }

    func testPreferencesReturnConfiguredDurations() {
        var preferences = PomodoroPreferences.default
        preferences.workMinutes = 40
        preferences.shortBreakMinutes = 7
        preferences.longBreakMinutes = 22

        XCTAssertEqual(preferences.duration(for: .work), 2_400)
        XCTAssertEqual(preferences.duration(for: .shortBreak), 420)
        XCTAssertEqual(preferences.duration(for: .longBreak), 1_320)
    }
}
