#!/usr/bin/env bash
start_log() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/linux-dev-setup"
  mkdir -p -m 700 "$dir"
  LOG_FILE="$dir/$(date +%Y%m%d-%H%M%S).log"
  : > "$LOG_FILE"; chmod 600 "$LOG_FILE"
  printf 'Log: %s\n' "$LOG_FILE"
}
log_line() { printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG_FILE"; }
