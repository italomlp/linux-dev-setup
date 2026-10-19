#!/usr/bin/env bash
select_modules_interactively() {
  local i answer item index already name
  ui_heading 'Linux Dev Setup' 'Choose modules'
  printf '  0) All modules\n'
  for i in "${!MODULES[@]}"; do printf '  %d) %s\n' "$((i+1))" "${MODULES[i]}"; done
  printf '  q) Quit\n\n'
  ui_style heading 'Numbers separated by commas (for example, 3,4,6): '
  if ! IFS= read -r answer; then echo 'No selection received' >&2; return 2; fi
  answer=${answer//[[:space:]]/}
  case $answer in
    0|a|all) SELECTED=("${MODULES[@]}");;
    q|Q) exit 0;;
    '') echo 'Invalid selection: empty' >&2; return 2;;
    *)
      local -a choices=()
      IFS=, read -ra choices <<< "$answer"
      SELECTED=()
      for item in "${choices[@]}"; do
        [[ $item =~ ^[0-9]+$ ]] || { echo "Invalid selection: $item" >&2; return 2; }
        index=$((10#$item))
        (( index >= 1 && index <= ${#MODULES[@]} )) || { echo "Invalid selection: $item" >&2; return 2; }
        name=${MODULES[index-1]}
        already=0
        for i in "${!SELECTED[@]}"; do [[ ${SELECTED[i]} != "$name" ]] || already=1; done
        (( already )) || SELECTED+=("$name")
      done;;
  esac
  printf '\n'; ui_style heading 'Selected modules:'; printf ' %s\n' "${SELECTED[*]}"
  for name in "${SELECTED[@]}"; do
    case $name in
      docker) ask_optional_component 'Incluir Docker Desktop no plano?' INSTALL_DOCKER_DESKTOP;;
      applications) ask_optional_component 'Incluir Flatpak e Zen no plano?' INSTALL_FLATPAK;;
    esac
  done
}
ask_optional_component() {
  local question=$1 variable=$2 answer current
  current=${!variable}
  while true; do
    ui_style heading "$question"; printf ' [S/n] (current: %s): ' "$current"
    if ! IFS= read -r answer; then return 0; fi
    case $answer in
      ''|s|S|y|Y) printf -v "$variable" '%s' 1; return 0;;
      n|N) printf -v "$variable" '%s' 0; return 0;;
      *) echo 'Responda s ou n.';;
    esac
  done
}
