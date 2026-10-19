#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/lib/planning.sh"
source "$ROOT/lib/package-manager.sh"
fail() { echo "FAIL: $*" >&2; exit 1; }
# A --yes run must stop before repository repair or actions without an interactive approval.
YES=1
add_action configure 'Repair sources' warp-repo-repair '' - ''
repair_warp_repo() { echo MUTATION; }
log_line() { :; }
run_action() { echo MUTATION; }
if out=$(execute_plan </dev/null 2>&1); then fail 'unattended destructive plan accepted'; fi
[[ $out != *MUTATION* ]] || fail 'mutation happened before confirmation'
[[ $out == *'interactive confirmation'* ]] || fail 'missing confirmation guidance'
# Read-only plans need no confirmation.
ACTION_TYPE=(); ACTION_STATUS=(); ACTION_TITLE=(); ACTION_ARG=(); ACTION_DEP=(); ACTION_RESULT=()
confirm_planned_changes
# Exercise explicit consent through the same reader used with /dev/tty.
if read_change_approval <<< yes; then fail 'generic yes accepted'; fi
if read_change_approval <<< ''; then fail 'empty consent accepted'; fi
read_change_approval <<< apply
printf 'ok - destructive plans require explicit interactive approval even with --yes\n'
# Even the log must be created only after approval.
start_log() { echo MUTATION; }
ACTION_STATUS=(configure); ACTION_TITLE=('Repair sources'); ACTION_TYPE=(warp-repo-repair); ACTION_ARG=(''); ACTION_DEP=(-); ACTION_NOTE=(''); ACTION_RESULT=(pending)
if out=$(execute_plan </dev/null 2>&1); then fail 'unattended plan accepted'; fi
[[ $out != *MUTATION* ]] || fail 'log created before confirmation'
