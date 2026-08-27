#!/usr/bin/env bash
set -euo pipefail

project="Pomodoro.xcodeproj/project.pbxproj"
scheme="Pomodoro.xcodeproj/xcshareddata/xcschemes/Pomodoro.xcscheme"
icon="PomodoroApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

test -f "$project"
test -f "$scheme"
test -f "$icon"

python3 - <<'PY'
import plistlib
import xml.etree.ElementTree as ET
from pathlib import Path

for value in (
    "PomodoroApp/Info.plist",
    "PomodoroApp/Pomodoro.entitlements",
    "PomodoroLiveActivity/Info.plist",
):
    with Path(value).open("rb") as handle:
        plistlib.load(handle)

for value in (
    "Pomodoro.xcodeproj/project.xcworkspace/contents.xcworkspacedata",
    "Pomodoro.xcodeproj/xcshareddata/xcschemes/Pomodoro.xcscheme",
):
    ET.parse(value)
PY

python3 -m json.tool PomodoroApp/Assets.xcassets/Contents.json >/dev/null
python3 -m json.tool PomodoroApp/Assets.xcassets/AccentColor.colorset/Contents.json >/dev/null
python3 -m json.tool PomodoroApp/Assets.xcassets/AppIcon.appiconset/Contents.json >/dev/null

if command -v identify >/dev/null 2>&1; then
    dimensions="$(identify -format '%wx%h' "$icon")"
    test "$dimensions" = "1024x1024"
elif command -v sips >/dev/null 2>&1; then
    width="$(sips -g pixelWidth "$icon" | awk '/pixelWidth/ {print $2}')"
    height="$(sips -g pixelHeight "$icon" | awk '/pixelHeight/ {print $2}')"
    test "$width" = "1024"
    test "$height" = "1024"
else
    echo "No image inspection utility found." >&2
    exit 1
fi

grep -q 'NSSupportsLiveActivities' PomodoroApp/Info.plist
grep -q 'com.apple.widgetkit-extension' PomodoroLiveActivity/Info.plist
grep -q 'PomodoroLiveActivity.appex in Embed App Extensions' "$project"
grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 27.0' "$project"
grep -q 'BlueprintName="Pomodoro"' "$scheme"

while IFS= read -r source; do
    basename="$(basename "$source")"
    if ! grep -q "$basename" "$project"; then
        echo "Swift source missing from Xcode project: $source" >&2
        exit 1
    fi
done < <(find PomodoroApp PomodoroShared PomodoroLiveActivity PomodoroTests -name '*.swift' -type f | sort)

echo "Static project validation passed."
