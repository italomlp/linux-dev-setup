#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
unset DS_TEST_MODE DS_TEST_FORCE_MISSING DS_TEST_IGNORE_REPOS DS_TEST_OS_RELEASE DS_TEST_ARCH
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
check() { [[ $2 == *"$3"* ]] || fail "$1: expected $3"; printf 'ok - %s\n' "$1"; }

plain=$(ROOT="$ROOT" TERM=xterm-256color bash -c 'source "$ROOT/lib/ui.sh"; ui_init; ui_heading "Linux Dev Setup" "Dry run"')
check plain-heading "$plain" 'Linux Dev Setup'
[[ $plain != *$'\033['* ]] || fail 'redirected output contains ANSI escapes'
printf 'ok - plain-output\n'

color=$(env -u NO_COLOR ROOT="$ROOT" TERM=xterm-256color script -qec 'bash -c '\''source "$ROOT/lib/ui.sh"; ui_init; ui_heading "Linux Dev Setup" "Dry run"'\''' /dev/null)
[[ $color == *$'\033['* ]] || fail 'terminal output lacks ANSI emphasis'
printf 'ok - terminal-color\n'

no_color=$(ROOT="$ROOT" TERM=xterm-256color NO_COLOR=1 script -qec 'bash -c '\''source "$ROOT/lib/ui.sh"; ui_init; ui_heading "Linux Dev Setup" "Dry run"'\''' /dev/null)
[[ $no_color != *$'\033['* ]] || fail 'NO_COLOR did not disable ANSI escapes'
printf 'ok - no-color\n'

dumb=$(env -u NO_COLOR ROOT="$ROOT" TERM=dumb script -qec 'bash -c '\''source "$ROOT/lib/ui.sh"; ui_init; ui_heading "Linux Dev Setup" "Dry run"'\''' /dev/null)
[[ $dumb != *$'\033['* ]] || fail 'TERM=dumb did not disable ANSI escapes'
printf 'ok - dumb-terminal\n'

plan=$(bash "$ROOT/install.sh" --module system --dry-run)
check plan-heading "$plan" 'Linux Dev Setup'
check plan-module-context "$plan" 'Modules: system'
check plan-section-count "$plan" 'Already installed:  ('
[[ $plan != *'Will update:  (0)'* ]] || fail 'dry-run shows empty sections'
printf 'ok - empty-sections-hidden\n'
[[ $plan != *$'\033['* ]] || fail 'dry-run pipe contains ANSI escapes'
printf 'ok - dry-run-plain\n'

menu=$(printf '0\n' | bash "$ROOT/install.sh" --interactive --dry-run)
check menu-heading "$menu" 'Choose modules'
check menu-selection "$menu" 'Selected modules:'

checklist=$(ROOT="$ROOT" bash -c '
  source "$ROOT/lib/ui.sh"; ui_init
  source "$ROOT/lib/checklist.sh"
  checklist_catalog() { CHECKLIST_IDS=(gh); CHECKLIST_NAMES=("GitHub CLI"); CHECKLIST_KINDS=(cli); }
  checklist_status() { printf pending; }
  checklist_detail() { printf "Sign in with the browser."; }
  run_checklist 1
')
check checklist-heading "$checklist" 'Linux Dev Setup'
check checklist-status "$checklist" '[pending]'
check checklist-next-action "$checklist" 'Sign in with the browser.'

terminal_helper=$(printf '\n' | bash "$ROOT/scripts/checklist-terminal.sh" restic)
check checklist-terminal-heading "$terminal_helper" 'Linux Dev Setup'

diagnostics=$(bash "$ROOT/diagnose.sh")
check diagnostics-heading "$diagnostics" 'Linux Dev Setup'

progress=$(ROOT="$ROOT" TMP="$TMP" bash -c '
  source "$ROOT/lib/ui.sh"; ui_init
  source "$ROOT/lib/planning.sh"
  source "$ROOT/lib/logging.sh"
  source "$ROOT/lib/package-manager.sh"
  LOG_FILE="$TMP/action.log"; : > "$LOG_FILE"
  run_action() { :; }
  add_action install "Sample tool" apt sample - ""
  execute_plan
')
check progress-heading "$progress" 'Execution progress'
check progress-success "$progress" '[ok]'
check progress-summary "$progress" '[1 completed]'
[[ $(cat "$TMP/action.log") != *$'\033['* ]] || fail 'installation log contains ANSI escapes'
printf 'ok - plain-log\n'

terminal_plan=$(env -u NO_COLOR TERM=xterm-256color script -qec "bash '$ROOT/install.sh' --module system --dry-run" /dev/null)
[[ $terminal_plan == *$'\033['* ]] || fail 'terminal dry-run lacks ANSI emphasis'
printf 'ok - terminal-dry-run-color\n'

terminal_no_color_plan=$(NO_COLOR=1 TERM=xterm-256color script -qec "bash '$ROOT/install.sh' --module system --dry-run" /dev/null)
[[ $terminal_no_color_plan != *$'\033['* ]] || fail 'NO_COLOR dry-run contains ANSI escapes'
printf 'ok - terminal-dry-run-no-color\n'

package_output=$(bash "$ROOT/scripts/package.sh" --output "$TMP/dist")
check package-heading "$package_output" 'Linux Dev Setup'

grep -Fq 'Downloading verified release' "$ROOT/scripts/bootstrap.sh.in" || fail 'remote installer lacks download progress label'
printf 'ok - bootstrap-progress-label\n'
