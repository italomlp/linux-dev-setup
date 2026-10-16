#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$ROOT/lib/detection.sh"
source "$ROOT/lib/planning.sh"
source "$ROOT/lib/logging.sh"
source "$ROOT/lib/package-manager.sh"
source "$ROOT/lib/interactive.sh"
source "$ROOT/config/settings.conf"
MODULES=(system terminal javascript docker editors ai-agents local-llms android applications productivity)
usage() { cat <<'EOF'
Usage: ./install.sh [--interactive | --all | --module name[,name...]] [--dry-run] [--yes]
       ./install.sh --list | --help
Dry-run is the default when no selection is given.
EOF
}
DRY_RUN=0; YES=0; INTERACTIVE=0; SELECTED=()
if (( $# == 0 )); then DRY_RUN=1; fi
while (( $# )); do
  case $1 in
    --help|-h) usage; exit 0;;
    --list) printf '%s\n' "${MODULES[@]}"; exit 0;;
    --all) SELECTED=("${MODULES[@]}");;
    --interactive) INTERACTIVE=1;;
    --module)
      (( $# >= 2 )) || { echo '--module requires a value' >&2; exit 2; }
      IFS=, read -ra names <<< "$2"
      SELECTED+=("${names[@]}"); shift;;
    --dry-run) DRY_RUN=1;;
    --yes) YES=1;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2;;
  esac
  shift
done
if (( INTERACTIVE )) && [[ -n ${SELECTED[*]-} ]]; then
  echo '--interactive cannot be combined with --all or --module' >&2; exit 2
fi
if (( INTERACTIVE )); then select_modules_interactively
elif [[ -z ${SELECTED[*]-} ]]; then SELECTED=("${MODULES[@]}"); fi
for name in "${SELECTED[@]}"; do
  valid=0
  for known in "${MODULES[@]}"; do [[ $name != "$known" ]] || valid=1; done
  (( valid )) || { echo "Unknown module: $name" >&2; exit 2; }
done
detect_system
if [[ ${DS_TEST_MODE:-0} != 1 && -e /etc/apt/sources.list.d/claude-desktop.list && -e /etc/apt/sources.list.d/linux-dev-setup-claude-desktop.list ]]; then
  APT_SOURCE_PARTS_OVERRIDE=$(mktemp -d)
  trap 'rm -rf "$APT_SOURCE_PARTS_OVERRIDE"' EXIT
  cp -a /etc/apt/sources.list.d/. "$APT_SOURCE_PARTS_OVERRIDE/"
  rm -f "$APT_SOURCE_PARTS_OVERRIDE/linux-dev-setup-claude-desktop.list"
  add_action configure 'Claude Desktop repository repair' claude-repo-repair '' - 'remove duplicate installer APT source; retain package-managed source'
fi
for name in "${SELECTED[@]}"; do
  source "$ROOT/modules/$name.sh"
  "plan_${name//-/_}"
done
print_plan
if (( DRY_RUN )); then exit 0; fi
if [[ ${DS_TEST_MODE:-0} == 1 ]]; then echo 'Test fixture mode cannot execute changes' >&2; exit 2; fi
if (( EUID == 0 )); then echo 'Run as a normal user, not root' >&2; exit 2; fi
if (( ! YES )); then
  [[ -t 0 ]] || { echo 'Non-interactive execution requires --yes' >&2; exit 2; }
  printf '\nExecute this plan? [y/N] '
  read -r answer
  [[ $answer == y || $answer == Y ]] || exit 0
fi
start_log
execute_plan
