#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 2 ]]; then
    echo "usage: package-unsigned-ipa.sh APP_PATH OUTPUT_IPA" >&2
    exit 64
fi

app_path="$1"
output_path="$2"

test -d "$app_path"
test -f "$app_path/Info.plist"
test -d "$app_path/PlugIns/PomodoroLiveActivity.appex"
test -f "$app_path/PlugIns/PomodoroLiveActivity.appex/Info.plist"

mkdir -p "$(dirname "$output_path")"
output_directory="$(cd "$(dirname "$output_path")" && pwd)"
output_path="$output_directory/$(basename "$output_path")"

package_directory="$(mktemp -d)"
cleanup() {
    rm -rf -- "$package_directory"
}
trap cleanup EXIT

mkdir -p "$package_directory/Payload"
ditto "$app_path" "$package_directory/Payload/Pomodoro.app"

(
    cd "$package_directory"
    /usr/bin/zip -qry -X "$output_path" Payload
)

unzip -Z1 "$output_path" | grep -qx 'Payload/Pomodoro.app/Info.plist'
unzip -Z1 "$output_path" | grep -qx 'Payload/Pomodoro.app/PlugIns/PomodoroLiveActivity.appex/Info.plist'

echo "Created unsigned IPA: $output_path"
