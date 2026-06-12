#!/bin/bash
set -euo pipefail

DIR="$HOME/.cursor"
PIDFILE="$DIR/agent-caffeinate.pid"
COUNTFILE="$DIR/agent-caffeinate.count"

start_inhibitor() {
  if command -v systemd-inhibit >/dev/null 2>&1; then
    systemd-inhibit \
      --what=idle:sleep:handle-lid-switch:handle-power-key \
      --who=cursor-agent \
      --why="Cursor agent session" \
      --mode=block \
      sleep infinity &
    echo $!
    return 0
  fi

  if command -v caffeinate >/dev/null 2>&1; then
    caffeinate -dims &
    echo $!
    return 0
  fi

  return 1
}

mkdir -p "$DIR"

count=0
if [[ -f "$COUNTFILE" ]]; then
  count=$(tr -d '[:space:]' <"$COUNTFILE" 2>/dev/null || echo 0)
fi
[[ "$count" =~ ^[0-9]+$ ]] || count=0

count=$((count + 1))
echo "$count" >"$COUNTFILE"

if [[ "$count" -eq 1 ]]; then
  if [[ -f "$PIDFILE" ]]; then
    pid=$(tr -d '[:space:]' <"$PIDFILE" 2>/dev/null || true)
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      exit 0
    fi
    rm -f "$PIDFILE"
  fi

  if pid="$(start_inhibitor)"; then
    echo "$pid" >"$PIDFILE"
  fi
fi

exit 0
