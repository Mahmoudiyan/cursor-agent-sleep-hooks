#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Install Cursor sleep hooks on this machine.

Options:
  --remote [host ...]  Also install on SSH hosts (Linux servers for Remote SSH)
  --remote-all         Also install on all hosts in remote-hosts.txt
  -h, --help           Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --remote dev-server
  $(basename "$0") --remote-all
EOF
}

REMOTE_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        REMOTE_ARGS+=("$1")
        shift
      done
      ;;
    --remote-all)
      REMOTE_ARGS=(--all)
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

CURSOR_DIR="$HOME/.cursor"
HOOKS_DIR="$CURSOR_DIR/hooks"

os="$(uname -s)"
case "$os" in
  Darwin) PLATFORM=mac ;;
  Linux) PLATFORM=linux ;;
  *)
    echo "Unsupported OS: $os"
    echo "On Windows, run: install.ps1"
    exit 1
    ;;
esac

SRC="$ROOT/$PLATFORM"
if [[ ! -d "$SRC" ]]; then
  echo "Missing platform files: $SRC"
  exit 1
fi

mkdir -p "$HOOKS_DIR"

cp "$SRC/hooks.json" "$CURSOR_DIR/hooks.json"
cp "$SRC"/prevent-sleep-* "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR"/prevent-sleep-*.sh 2>/dev/null || true

echo "Installed $PLATFORM hooks to $CURSOR_DIR"

if [[ ${#REMOTE_ARGS[@]} -gt 0 ]]; then
  echo ""
  "$ROOT/install-remote.sh" "${REMOTE_ARGS[@]}"
fi

echo "Restart Cursor, then check Settings -> Hooks."
