#!/usr/bin/env python3
"""Set the marketing and build versions for every Xcode target."""

from __future__ import annotations

import re
import sys
from pathlib import Path


PROJECT = Path("Pomodoro.xcodeproj/project.pbxproj")
SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
BUILD = re.compile(r"^[1-9][0-9]*$")


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: set-version.py X.X.X BUILD_NUMBER")

    version, build = sys.argv[1:]
    if not SEMVER.fullmatch(version):
        raise SystemExit(f"invalid release version: {version!r}; expected X.X.X")
    if not BUILD.fullmatch(build):
        raise SystemExit(f"invalid build number: {build!r}; expected a positive integer")

    text = PROJECT.read_text()
    marketing_values = re.findall(r"MARKETING_VERSION = ([^;]+);", text)
    build_values = re.findall(r"CURRENT_PROJECT_VERSION = ([^;]+);", text)

    if not marketing_values or not build_values:
        raise SystemExit("project version settings were not found")
    if len(set(marketing_values)) != 1:
        raise SystemExit(f"marketing versions are already inconsistent: {marketing_values}")
    if len(set(build_values)) != 1:
        raise SystemExit(f"build versions are already inconsistent: {build_values}")

    text, marketing_count = re.subn(
        r"MARKETING_VERSION = [^;]+;",
        f"MARKETING_VERSION = {version};",
        text,
    )
    text, build_count = re.subn(
        r"CURRENT_PROJECT_VERSION = [^;]+;",
        f"CURRENT_PROJECT_VERSION = {build};",
        text,
    )
    PROJECT.write_text(text)

    print(f"Set MARKETING_VERSION={version} in {marketing_count} configurations")
    print(f"Set CURRENT_PROJECT_VERSION={build} in {build_count} configurations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
