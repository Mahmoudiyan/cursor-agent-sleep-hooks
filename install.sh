#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
echo "Restart Cursor, then check Settings -> Hooks."
