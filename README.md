# Pomodoro

A deliberately small, native Pomodoro timer for iOS 27. The app uses SwiftUI, ActivityKit, WidgetKit, local notifications, timestamp-based persistence, and system Liquid Glass controls.

## What is included

- Focus, short-break, and long-break intervals
- Configurable durations and cycle length
- Pause, resume, skip, stop/reset, automatic transitions, and optional automatic start
- Persistent timestamp-based session state that reconciles after suspension or termination
- Local notifications and foreground haptics
- Lock Screen and Dynamic Island Live Activity
- Unit tests and a shared Xcode scheme
- GitHub Actions build and test verification on the `xcode-27` runner

The product intentionally has no tasks, projects, accounts, analytics, network layer, or gamification.

## Requirements

- Xcode 27 beta or newer
- iOS 27 SDK
- iPhone running iOS 27 for device testing

Open `Pomodoro.xcodeproj`, select the `Pomodoro` scheme, and run the app. Xcode manages signing automatically once a development team is selected locally.

## Architecture

`PomodoroTimer` owns the session state and transitions. A running session persists an absolute end date rather than decrementing an in-memory counter. `NotificationManager` schedules interval alerts, and `LiveActivityManager` publishes date-driven ActivityKit content so the system renders the countdown without per-second app updates.

The Live Activity is intentionally glanceable and read-only. Its compact presentation contains only an interval SF Symbol and remaining time; controls remain in the app so state, notifications, and persistence cannot diverge across processes.

## Verification

On macOS with Xcode 27:

```sh
./Scripts/validate-project.sh
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO clean build
```

CI additionally runs the unit tests on an iOS 27 simulator. Batch changes before pushing; use the workflow as the final compile authority rather than triggering it after every small edit.
