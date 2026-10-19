#!/usr/bin/env bash
start_log() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/linux-dev-setup"
  mkdir -p -m 700 "$dir"
  LOG_FILE="$dir/$(date +%Y%m%d-%H%M%S).log"
  : > "$LOG_FILE"; chmod 600 "$LOG_FILE"
  printf 'Log: %s\n' "$LOG_FILE"
}
log_line() {
  local stamp message label detail role badge
  stamp=$(date '+%F %T'); message=$*
  printf '%s %s\n' "$stamp" "$message" >> "$LOG_FILE"
  if declare -F ui_badge >/dev/null; then
    label=${message%% *}; detail=${message#* }
    case $label in
      START) role=pending; badge=start;;
      OK) role=ok; badge=ok;;
      FAIL) role=fail; badge=fail;;
      SKIP) role=skipped; badge=skip;;
      FOLLOW-UP) role=manual; badge=follow-up;;
      *) role=note; badge=$label;;
    esac
    printf '%s ' "$stamp"; ui_badge "$role" "$badge"; printf ' %s\n' "$detail"
  else
    printf '%s %s\n' "$stamp" "$message"
  fi
}
