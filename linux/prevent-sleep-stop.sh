#!/bin/bash
set -euo pipefail

DIR="$HOME/.cursor"
PIDFILE="$DIR/agent-caffeinate.pid"
COUNTFILE="$DIR/agent-caffeinate.count"

count=0
if [[ -f "$COUNTFILE" ]]; then
  count=$(tr -d '[:space:]' <"$COUNTFILE" 2>/dev/null || echo 0)
fi
[[ "$count" =~ ^[0-9]+$ ]] || count=0

if [[ "$count" -le 0 ]]; then
  exit 0
fi

count=$((count - 1))
echo "$count" >"$COUNTFILE"

if [[ "$count" -eq 0 ]] && [[ -f "$PIDFILE" ]]; then
  pid=$(tr -d '[:space:]' <"$PIDFILE" 2>/dev/null || true)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$PIDFILE"
fi

exit 0
