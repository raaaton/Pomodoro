import SwiftUI

struct TimerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var timer = PomodoroTimer()
    @State private var presentsSettings = false
    @State private var confirmsReset = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                intervalHeader
                    .padding(.bottom, 24)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    TimerProgressView(session: timer.session, date: context.date)
                }
                .frame(maxWidth: 390)
                .padding(.horizontal, 28)

                CycleIndicator(
                    current: timer.session.workNumber,
                    total: timer.preferences.workIntervalsBeforeLongBreak
                )
                .padding(.top, 26)

                Spacer(minLength: 34)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
            }
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        presentsSettings = true
                    }
                }
            }
            .sheet(isPresented: $presentsSettings) {
                SettingsView(timer: timer)
            }
            .confirmationDialog(
                "Stop this session?",
                isPresented: $confirmsReset,
                titleVisibility: .visible
            ) {
                Button("Stop and Reset", role: .destructive) { timer.reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The timer will return to the first focus interval.")
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { timer.sceneBecameActive() }
            }
            .task {
                while !Task.isCancelled {
                    if timer.session.status == .running {
                        try? await Task.sleep(for: .milliseconds(500))
                        timer.tick()
                    } else {
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            }
        }
    }

    private var intervalHeader: some View {
        Label(timer.session.interval.title, systemImage: timer.session.interval.systemImage)
            .font(.headline)
            .foregroundStyle(.secondary)
            .animation(.spring(duration: 0.4), value: timer.session.interval)
    }

    private var controls: some View {
        HStack(spacing: 20) {
            if timer.session.status != .ready || timer.canSkip {
                controlButton(
                    title: "Stop",
                    systemImage: "xmark",
                    action: { confirmsReset = true }
                )
            } else {
                Color.clear.frame(width: 64, height: 64)
            }

            primaryButton

            if timer.session.status != .ready {
                controlButton(
                    title: "Skip",
                    systemImage: "forward.end.fill",
                    action: timer.skip
                )
            } else {
                Color.clear.frame(width: 64, height: 64)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var primaryButton: some View {
        Button(action: primaryAction) {
            Image(systemName: timer.session.status == .running ? "pause.fill" : "play.fill")
                .font(.title2.weight(.semibold))
                .frame(width: 82, height: 82)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .accessibilityLabel(timer.session.status == .running ? "Pause" : "Start")
    }

    private func controlButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 64, height: 64)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(title)
    }

    private func primaryAction() {
        if timer.session.status == .running {
            timer.pause()
        } else {
            timer.startOrResume()
        }
    }
}
