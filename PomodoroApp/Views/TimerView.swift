import SwiftUI

struct TimerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var timer = PomodoroTimer()
    @State private var presentsSettings = false
    @State private var confirmsReset = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 22) {
                    intervalHeader

                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        TimerProgressView(session: timer.session, date: context.date)
                    }
                    .frame(maxWidth: 310)

                    CycleIndicator(
                        current: timer.session.workNumber,
                        total: timer.preferences.workIntervalsBeforeLongBreak
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.horizontal, 32)

                Spacer(minLength: 28)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
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
            .tint(.orange)
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
        HStack(spacing: 8) {
            Image(systemName: timer.session.interval.systemImage)
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            Text(timer.session.interval.title)
                .foregroundStyle(.primary)
        }
        .font(.headline.weight(.semibold))
        .animation(.spring(duration: 0.4), value: timer.session.interval)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            secondaryControlButton(
                title: "Stop",
                systemImage: "xmark",
                isVisible: timer.session.status != .ready || timer.canSkip,
                action: { confirmsReset = true }
            )

            primaryButton

            secondaryControlButton(
                title: "Skip",
                systemImage: "forward.end.fill",
                isVisible: timer.session.status != .ready,
                action: timer.skip
            )
        }
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
        .animation(.snappy(duration: 0.3), value: timer.session.status)
    }

    private var primaryButton: some View {
        Button(action: primaryAction) {
            Label(primaryTitle, systemImage: primarySystemImage)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(.orange)
        .accessibilityLabel(primaryTitle)
        .frame(maxWidth: 172)
    }

    private func secondaryControlButton(
        title: String,
        systemImage: String,
        isVisible: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(title)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .frame(width: 50)
    }

    private var primaryTitle: String {
        switch timer.session.status {
        case .ready: "Start"
        case .running: "Pause"
        case .paused: "Resume"
        }
    }

    private var primarySystemImage: String {
        timer.session.status == .running ? "pause.fill" : "play.fill"
    }

    private func primaryAction() {
        if timer.session.status == .running {
            timer.pause()
        } else {
            timer.startOrResume()
        }
    }
}
