#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
REMOTE="${1:-git@github.com:Mahmoudiyan/cursor-agent-sleep-hooks.git}"

git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh repo create Mahmoudiyan/cursor-agent-sleep-hooks \
    --public \
    --source=. \
    --remote=origin \
    --push \
    --description "Cross-platform Cursor hooks to prevent sleep during agent sessions"
  echo "Published to https://github.com/Mahmoudiyan/cursor-agent-sleep-hooks"
  exit 0
fi

if git ls-remote "$REMOTE" >/dev/null 2>&1; then
  git push -u origin main
  echo "Pushed to $REMOTE"
  exit 0
fi

cat <<EOF
GitHub repo does not exist yet (or gh is not logged in).

Option A — create repo in browser, then push:
  1. Open https://github.com/new?name=cursor-agent-sleep-hooks
  2. Create a public empty repo (no README)
  3. Run: git push -u origin main

Option B — use GitHub CLI:
  gh auth login
  ./publish.sh
EOF
exit 1
