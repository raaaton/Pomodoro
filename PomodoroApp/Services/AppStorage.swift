import Foundation

final class AppStorage: @unchecked Sendable {
    private enum Key {
        static let preferences = "pomodoro.preferences.v1"
        static let session = "pomodoro.session.v1"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadPreferences() -> PomodoroPreferences {
        guard
            let data = defaults.data(forKey: Key.preferences),
            let value = try? decoder.decode(PomodoroPreferences.self, from: data)
        else { return .default }
        return value
    }

    func save(_ preferences: PomodoroPreferences) {
        guard let data = try? encoder.encode(preferences) else { return }
        defaults.set(data, forKey: Key.preferences)
    }

    func loadSession() -> TimerSession? {
        guard
            let data = defaults.data(forKey: Key.session),
            let value = try? decoder.decode(TimerSession.self, from: data)
        else { return nil }
        return value
    }

    func save(_ session: TimerSession) {
        guard let data = try? encoder.encode(session) else { return }
        defaults.set(data, forKey: Key.session)
    }
}
