#!/usr/bin/env bash
set -euo pipefail
# Set GODOT to override the binary path (e.g. GODOT=/path/to/godot scripts/run_tests.sh)
# macOS default: /Applications/Godot.app/Contents/MacOS/Godot
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT" --headless --import
"$GODOT" --headless -s res://addons/gut/gut_cmdln.gd
