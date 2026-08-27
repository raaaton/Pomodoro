import SwiftUI

struct TimerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var timer = PomodoroTimer()
    @State private var presentsSettings = false
    @State private var confirmsReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                immersiveBackground

                VStack(spacing: 0) {
                    Spacer(minLength: 56)

                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        TimerHeroView(
                            session: timer.session,
                            date: context.date,
                            cycleTarget: timer.preferences.workIntervalsBeforeLongBreak
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 48)

                    sessionControl
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    actionsMenu
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
            .onReceive(NotificationCenter.default.publisher(for: .pomodoroSessionDidChange)) { _ in
                timer.reloadFromStorage()
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
        .preferredColorScheme(.dark)
    }

    private var immersiveBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.067, green: 0.082, blue: 0.133),
                    Color(red: 0.031, green: 0.039, blue: 0.063)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [.orange.opacity(0.075), .clear],
                center: .center,
                startRadius: 12,
                endRadius: 270
            )
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var sessionControl: some View {
        if timer.session.status == .ready {
            primaryButton
        } else {
            HoldToStopControl(interval: timer.session.interval) {
                timer.reset()
            }
        }
    }

    private var primaryButton: some View {
        Button(action: timer.startOrResume) {
            Label("Start", systemImage: "play.fill")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(.orange)
        .accessibilityLabel("Start")
        .frame(maxWidth: 200)
    }

    private var actionsMenu: some View {
        Menu {
            if timer.session.status != .ready {
                Button(
                    timer.session.status == .running ? "Pause" : "Resume",
                    systemImage: timer.session.status == .running ? "pause.fill" : "play.fill"
                ) {
                    if timer.session.status == .running {
                        timer.pause()
                    } else {
                        timer.startOrResume()
                    }
                }

                Button("Skip", systemImage: "forward.end.fill") {
                    timer.skip()
                }

                Divider()

                Button("Reset", systemImage: "arrow.counterclockwise", role: .destructive) {
                    confirmsReset = true
                }

                Divider()
            }

            Button("Settings", systemImage: "gearshape") {
                presentsSettings = true
            }
        } label: {
            Label("Session Actions", systemImage: "ellipsis")
        }
    }
}
