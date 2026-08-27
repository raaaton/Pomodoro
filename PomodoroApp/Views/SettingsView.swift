import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let timer: PomodoroTimer

    var body: some View {
        NavigationStack {
            Form {
                Section("Intervals") {
                    minuteStepper(
                        title: "Focus",
                        systemImage: "book.closed.fill",
                        value: timer.preferences.workMinutes,
                        range: 1...120,
                        set: { value in
                            timer.updatePreferences { $0.workMinutes = value }
                        }
                    )
                    minuteStepper(
                        title: "Short Break",
                        systemImage: "cup.and.saucer.fill",
                        value: timer.preferences.shortBreakMinutes,
                        range: 1...60,
                        set: { value in
                            timer.updatePreferences { $0.shortBreakMinutes = value }
                        }
                    )
                    minuteStepper(
                        title: "Long Break",
                        systemImage: "moon.zzz.fill",
                        value: timer.preferences.longBreakMinutes,
                        range: 1...90,
                        set: { value in
                            timer.updatePreferences { $0.longBreakMinutes = value }
                        }
                    )
                }

                Section("Cycle") {
                    Stepper(
                        value: Binding(
                            get: { timer.preferences.workIntervalsBeforeLongBreak },
                            set: { value in
                                timer.updatePreferences { $0.workIntervalsBeforeLongBreak = value }
                            }
                        ),
                        in: 2...8
                    ) {
                        LabeledContent("Long Break After") {
                            Text("\(timer.preferences.workIntervalsBeforeLongBreak) focus intervals")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(
                        "Start Intervals Automatically",
                        isOn: Binding(
                            get: { timer.preferences.automaticallyStartNextInterval },
                            set: { value in
                                timer.updatePreferences { $0.automaticallyStartNextInterval = value }
                            }
                        )
                    )
                }

                Section("Alerts") {
                    Toggle(
                        "Notifications",
                        isOn: Binding(
                            get: { timer.preferences.notificationsEnabled },
                            set: { value in
                                timer.updatePreferences { $0.notificationsEnabled = value }
                                if value {
                                    Task { _ = await NotificationManager.shared.requestAuthorization() }
                                }
                            }
                        )
                    )
                } footer: {
                    Text("Pomodoro uses notifications and haptics to mark the end of each interval.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func minuteStepper(
        title: String,
        systemImage: String,
        value: Int,
        range: ClosedRange<Int>,
        set: @escaping (Int) -> Void
    ) -> some View {
        Stepper(value: Binding(get: { value }, set: set), in: range) {
            Label {
                LabeledContent(title) {
                    Text("\(value) min")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
