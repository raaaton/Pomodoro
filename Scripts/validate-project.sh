#!/usr/bin/env bash
set -euo pipefail

project="Pomodoro.xcodeproj/project.pbxproj"
scheme="Pomodoro.xcodeproj/xcshareddata/xcschemes/Pomodoro.xcscheme"
icon="PomodoroApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

test -f "$project"
test -f "$scheme"
test -f "$icon"
test -x Scripts/package-unsigned-ipa.sh
test -x Scripts/set-version.py
test -f .github/workflows/release.yml

bash -n Scripts/package-unsigned-ipa.sh Scripts/validate-project.sh

python3 - <<'PY'
import ast
from pathlib import Path

ast.parse(Path("Scripts/set-version.py").read_text())
PY

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

python3 - <<'PY'
import re
from pathlib import Path

text = Path("Pomodoro.xcodeproj/project.pbxproj").read_text()
marketing = re.findall(r"MARKETING_VERSION = ([^;]+);", text)
builds = re.findall(r"CURRENT_PROJECT_VERSION = ([^;]+);", text)

if not marketing or len(set(marketing)) != 1:
    raise SystemExit(f"MARKETING_VERSION values are missing or inconsistent: {marketing}")
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", marketing[0]):
    raise SystemExit(f"MARKETING_VERSION is not X.X.X: {marketing[0]}")
if not builds or len(set(builds)) != 1:
    raise SystemExit(f"CURRENT_PROJECT_VERSION values are missing or inconsistent: {builds}")
if not re.fullmatch(r"[1-9][0-9]*", builds[0]):
    raise SystemExit(f"CURRENT_PROJECT_VERSION is not a positive integer: {builds[0]}")
PY

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
grep -q 'frame(width: 42, alignment: .trailing)' PomodoroLiveActivity/PomodoroLiveActivity.swift

if grep -q 'fixedSize(horizontal: true' PomodoroLiveActivity/PomodoroLiveActivity.swift; then
    echo "Live Activity timer views must not request unbounded horizontal size." >&2
    exit 1
fi

grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 27.0' "$project"
grep -q 'BlueprintName="Pomodoro"' "$scheme"
grep -q 'workflow_dispatch:' .github/workflows/release.yml
grep -q 'gh release create' .github/workflows/release.yml
grep -q 'package-unsigned-ipa.sh' .github/workflows/build.yml
grep -Fq 'Artifacts/Pomodoro-${version}.ipa' .github/workflows/build.yml
grep -Fq 'Artifacts/Pomodoro-${VERSION}.ipa' .github/workflows/release.yml

if grep -q -- '-unsigned\.ipa' .github/workflows/build.yml .github/workflows/release.yml; then
    echo "Workflow IPA filenames must use Pomodoro-X.X.X.ipa." >&2
    exit 1
fi

while IFS= read -r source; do
    basename="$(basename "$source")"
    if ! grep -q "$basename" "$project"; then
        echo "Swift source missing from Xcode project: $source" >&2
        exit 1
    fi
done < <(find PomodoroApp PomodoroShared PomodoroLiveActivity PomodoroTests -name '*.swift' -type f | sort)

echo "Static project validation passed."
