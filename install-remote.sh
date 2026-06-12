#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_FILE="$ROOT/remote-hosts.txt"
REPO_URL="${INSTALL_REPO_URL:-https://github.com/Mahmoudiyan/cursor-agent-sleep-hooks.git}"
REMOTE_DIR="${INSTALL_REMOTE_DIR:-cursor-agent-sleep-hooks}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [ssh-host ...]

Install Cursor sleep hooks on remote Linux servers (for Cursor Remote SSH).

Options:
  --all       Use hosts listed in remote-hosts.txt (one per line)
  -h, --help  Show this help

Examples:
  $(basename "$0") dev-server
  $(basename "$0") dev-server staging-server
  $(basename "$0") --all

Setup:
  cp remote-hosts.txt.example remote-hosts.txt
  # edit remote-hosts.txt with your SSH config host aliases

Requires: ssh access and git on each remote host.
EOF
}

read_hosts_file() {
  if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Missing $HOSTS_FILE — copy remote-hosts.txt.example and add your SSH hosts."
    exit 1
  fi

  local host
  while IFS= read -r host || [[ -n "$host" ]]; do
    host="${host%%#*}"
    host="$(echo "$host" | xargs)"
    [[ -n "$host" ]] && echo "$host"
  done <"$HOSTS_FILE"
}

install_on_host() {
  local host="$1"
  echo "==> $host"

  ssh -o ConnectTimeout=20 -o BatchMode=yes "$host" \
    "REPO_URL='$REPO_URL' REMOTE_DIR='$REMOTE_DIR' bash -s" <<'REMOTE'
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Skip: remote OS is not Linux ($(uname -s))"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed on remote host"
  exit 1
fi

TARGET="$HOME/$REMOTE_DIR"
if [[ -d "$TARGET/.git" ]]; then
  git -C "$TARGET" pull --ff-only
else
  git clone "$REPO_URL" "$TARGET"
fi

chmod +x "$TARGET/install.sh"
"$TARGET/install.sh"
REMOTE
}

collect_hosts() {
  local hosts=()
  local use_file=false
  local arg

  for arg in "$@"; do
    case "$arg" in
      --all) use_file=true ;;
      -h | --help)
        usage
        exit 0
        ;;
      -*)
        echo "Unknown option: $arg"
        usage
        exit 1
        ;;
      *) hosts+=("$arg") ;;
    esac
  done

  if $use_file; then
    while IFS= read -r host; do
      hosts+=("$host")
    done < <(read_hosts_file)
  fi

  if [[ ${#hosts[@]} -eq 0 ]]; then
    if [[ -f "$HOSTS_FILE" ]]; then
      while IFS= read -r host; do
        hosts+=("$host")
      done < <(read_hosts_file)
    fi
  fi

  if [[ ${#hosts[@]} -eq 0 ]]; then
    echo "No SSH hosts specified."
    echo "Pass host names, use --all, or create remote-hosts.txt"
    usage
    exit 1
  fi

  printf '%s\n' "${hosts[@]}"
}

main() {
  if ! command -v ssh >/dev/null 2>&1; then
    echo "Error: ssh is required"
    exit 1
  fi

  local hosts=()
  while IFS= read -r host; do
    hosts+=("$host")
  done < <(collect_hosts "$@")

  local failed=0
  local host
  for host in "${hosts[@]}"; do
    if ! install_on_host "$host"; then
      echo "Failed: $host" >&2
      failed=1
    fi
  done

  if [[ $failed -ne 0 ]]; then
    exit 1
  fi

  echo "Remote install complete. Reload Cursor Remote SSH windows and check Settings -> Hooks."
}

main "$@"
