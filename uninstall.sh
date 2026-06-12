#!/usr/bin/env bash
set -euo pipefail

CURSOR_DIR="$HOME/.cursor"
HOOKS_DIR="$CURSOR_DIR/hooks"

"$HOOKS_DIR/prevent-sleep-stop.sh" 2>/dev/null || true

rm -f "$CURSOR_DIR/hooks.json"
rm -f "$HOOKS_DIR/prevent-sleep-start.sh"
rm -f "$HOOKS_DIR/prevent-sleep-stop.sh"
rm -f "$HOOKS_DIR/prevent-sleep-start.cmd"
rm -f "$HOOKS_DIR/prevent-sleep-stop.cmd"
rm -f "$HOOKS_DIR/prevent-sleep-start.ps1"
rm -f "$HOOKS_DIR/prevent-sleep-stop.ps1"
rm -f "$HOOKS_DIR/prevent-sleep-daemon.ps1"
rm -f "$CURSOR_DIR/agent-caffeinate.pid"
rm -f "$CURSOR_DIR/agent-caffeinate.count"

echo "Removed Cursor agent sleep hooks."
