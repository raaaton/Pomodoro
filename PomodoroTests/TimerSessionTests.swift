import Foundation
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

    func testEndPolicyResetsMatchingSessionToFirstFocus() {
        var preferences = PomodoroPreferences.default
        preferences.workMinutes = 42
        var session = TimerSession.fresh(using: preferences)
        session.status = .running
        session.interval = .shortBreak
        session.workNumber = 3

        let reset = PomodoroSessionEndPolicy.resetSession(
            session,
            requestedID: session.id,
            preferences: preferences
        )

        XCTAssertEqual(reset?.status, .ready)
        XCTAssertEqual(reset?.interval, .work)
        XCTAssertEqual(reset?.workNumber, 1)
        XCTAssertEqual(reset?.pausedRemaining, 42 * 60)
        XCTAssertNotEqual(reset?.id, session.id)
    }

    func testEndPolicyIgnoresStaleLiveActivity() {
        let session = TimerSession.fresh(using: .default)

        let reset = PomodoroSessionEndPolicy.resetSession(
            session,
            requestedID: UUID(),
            preferences: .default
        )

        XCTAssertNil(reset)
    }

    func testHeroTimerFormattingRoundsUpRemainingSecond() {
        XCTAssertEqual(TimerHeroView.formatted(60.01), "01:01")
        XCTAssertEqual(TimerHeroView.formatted(0), "00:00")
        XCTAssertEqual(TimerHeroView.formatted(-5), "00:00")
    }
}
