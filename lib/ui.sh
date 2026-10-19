#!/usr/bin/env bash
# Presentation only. Call ui_init once after sourcing; never write styled text to logs.
UI_COLOR=0
ui_init() {
  UI_COLOR=0
  if [[ -t 1 && ${TERM:-dumb} != dumb && -z ${NO_COLOR+x} ]]; then UI_COLOR=1; fi
}
ui_style() {
  local role=$1 value=$2 code=''
  if (( UI_COLOR )); then
    case $role in
      title) code='1;36';;
      heading) code='1';;
      ready|ok|installed|marked) code='1;32';;
      install|configure|update) code='1;36';;
      pending|manual|review|configured*|'signed in locally'*) code='1;33';;
      fail|unsupported) code='1;31';;
      skipped|note|muted) code='2';;
    esac
  fi
  if [[ -n $code ]]; then printf '\033[%sm%s\033[0m' "$code" "$value"
  else printf '%s' "$value"; fi
}
ui_rule() {
  if (( UI_COLOR )); then ui_style muted '────────────────────────────────────────────────────────────'
  else printf '%s' '------------------------------------------------------------'; fi
  printf '\n'
}
ui_heading() {
  local title=$1 subtitle=${2:-}
  printf '\n'; ui_style title "$title"
  [[ -z $subtitle ]] || { printf '  '; ui_style muted "$subtitle"; }
  printf '\n'; ui_rule
}
ui_section() {
  local role=$1 title=$2 count=$3
  printf '\n'; ui_style heading "$title:"; printf '  '; ui_style "$role" "($count)"; printf '\n'
}
ui_subheading() {
  printf '\n'; ui_style heading "$1:"; printf '\n'
}
ui_badge() {
  local role=$1 label=$2
  printf '['; ui_style "$role" "$label"; printf ']'
}
