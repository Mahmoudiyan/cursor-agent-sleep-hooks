#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_FILE="$ROOT/remote-hosts.txt"
REMOTE_DIR="${INSTALL_REMOTE_DIR:-cursor-agent-sleep-hooks}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [ssh-host ...]

Remove Cursor sleep hooks from remote Linux servers.

Options:
  --all       Use hosts listed in remote-hosts.txt
  -h, --help  Show this help
EOF
}

read_hosts_file() {
  if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Missing $HOSTS_FILE"
    exit 1
  fi

  local host
  while IFS= read -r host || [[ -n "$host" ]]; do
    host="${host%%#*}"
    host="$(echo "$host" | xargs)"
    [[ -n "$host" ]] && echo "$host"
  done <"$HOSTS_FILE"
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
        exit 1
        ;;
      *) hosts+=("$arg") ;;
    esac
  done

  if $use_file; then
    while IFS= read -r host; do
      hosts+=("$host")
    done < <(read_hosts_file)
  elif [[ ${#hosts[@]} -eq 0 && -f "$HOSTS_FILE" ]]; then
    while IFS= read -r host; do
      hosts+=("$host")
    done < <(read_hosts_file)
  fi

  if [[ ${#hosts[@]} -eq 0 ]]; then
    echo "No SSH hosts specified."
    exit 1
  fi

  printf '%s\n' "${hosts[@]}"
}

uninstall_on_host() {
  local host="$1"
  echo "==> $host"

  ssh -o ConnectTimeout=20 -o BatchMode=yes "$host" \
    "REMOTE_DIR='$REMOTE_DIR' bash -s" <<'REMOTE'
set -euo pipefail

TARGET="$HOME/$REMOTE_DIR"
if [[ -x "$TARGET/uninstall.sh" ]]; then
  "$TARGET/uninstall.sh"
else
  CURSOR_DIR="$HOME/.cursor"
  rm -f "$CURSOR_DIR/hooks.json"
  rm -f "$CURSOR_DIR/hooks/prevent-sleep-"*
  rm -f "$CURSOR_DIR/agent-caffeinate.pid" "$CURSOR_DIR/agent-caffeinate.count"
fi
REMOTE
}

main() {
  local hosts=()
  while IFS= read -r host; do
    hosts+=("$host")
  done < <(collect_hosts "$@")

  local failed=0
  local host
  for host in "${hosts[@]}"; do
    if ! uninstall_on_host "$host"; then
      echo "Failed: $host" >&2
      failed=1
    fi
  done

  [[ $failed -eq 0 ]]
}

main "$@"
