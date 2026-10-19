#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$ROOT/lib/detection.sh"
source "$ROOT/lib/planning.sh"
source "$ROOT/lib/logging.sh"
source "$ROOT/lib/ui.sh"
ui_init
source "$ROOT/lib/package-manager.sh"
source "$ROOT/lib/interactive.sh"
source "$ROOT/lib/checklist.sh"
source "$ROOT/config/settings.conf"
MODULES=(system terminal javascript docker editors ai-agents local-llms android applications productivity)
usage() { cat <<'EOF'
Usage: ./install.sh [--interactive | --all | --module name[,name...]] [--dry-run] [--yes]
       ./install.sh --checklist [--dry-run]
       ./install.sh --list | --help
Dry-run is the default when no selection is given.
EOF
}
DRY_RUN=0; YES=0; INTERACTIVE=0; CHECKLIST=0; SELECTED=()
if (( $# == 0 )); then DRY_RUN=1; fi
while (( $# )); do
  case $1 in
    --help|-h) usage; exit 0;;
    --list) printf '%s\n' "${MODULES[@]}"; exit 0;;
    --all) SELECTED=("${MODULES[@]}");;
    --interactive) INTERACTIVE=1;;
    --checklist) CHECKLIST=1;;
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
if (( CHECKLIST )); then
  if (( INTERACTIVE || YES )) || [[ -n ${SELECTED[*]-} ]]; then
    echo '--checklist cannot be combined with module selection, --interactive or --yes' >&2; exit 2
  fi
  run_checklist "$DRY_RUN"
  exit $?
fi
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
  claude_plan_sources=$(mktemp -d)
  APT_SOURCE_PARTS_OVERRIDE=$claude_plan_sources
  trap 'rm -rf "$claude_plan_sources"' EXIT
  cp -a /etc/apt/sources.list.d/. "$APT_SOURCE_PARTS_OVERRIDE/"
  rm -f "$APT_SOURCE_PARTS_OVERRIDE/linux-dev-setup-claude-desktop.list"
  add_action configure 'Claude Desktop repository repair' claude-repo-repair '' - 'remove duplicate installer APT source; retain package-managed source'
fi
if [[ -f $(apt_source_dir)/linux-dev-setup-warp.list ]] && warp_vendor_source_present; then
  if warp_vendor_source_valid; then
    warp_plan_sources=$(mktemp -d)
    cp -a "${APT_SOURCE_PARTS_OVERRIDE:-$(apt_source_dir)}/." "$warp_plan_sources/"
    APT_SOURCE_PARTS_OVERRIDE=$warp_plan_sources
    trap 'rm -rf "$warp_plan_sources"; [[ -z ${claude_plan_sources:-} ]] || rm -rf "$claude_plan_sources"' EXIT
    rm -f "$APT_SOURCE_PARTS_OVERRIDE/linux-dev-setup-warp.list"
    add_action configure 'Warp repository repair' warp-repo-repair '' - 'Back up and remove duplicate installer source; retain verified Warp source'
  else
    plan_manual 'Warp repository repair' 'Vendor source is invalid; installer source retained. Repair vendor source before running APT.'
  fi
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
