#!/usr/bin/env bash
plan_terminal() {
  plan_known_apt Zsh zsh zsh
  local zsh_dep=-
  if [[ ${ACTION_STATUS[-1]} == install ]]; then zsh_dep=$((${#ACTION_TYPE[@]}-1)); fi
  plan_known_apt 'GNU Stow' stow stow
  if has_command zellij; then add_action installed Zellij none zellij - 'Existing installation retained'
  elif package_candidate zellij; then plan_apt Zellij zellij zellij
  elif [[ -n ${ZELLIJ_ARCHIVE:-} && -n ${ZELLIJ_SHA256:-} ]]; then add_action install Zellij release-tar "zellij:$ZELLIJ_ARCHIVE:$ZELLIJ_SHA256" - 'Verified official release archive to ~/.local/bin'
  else add_action install Zellij github-release-tar zellij - 'download verified Zellij release from GitHub; check published SHA-256 digest'; fi
  if has_command starship; then add_action installed Starship none starship - 'Existing installation retained'
  elif package_candidate starship; then plan_apt Starship starship starship
  elif [[ -n ${STARSHIP_ARCHIVE:-} && -n ${STARSHIP_SHA256:-} ]]; then add_action install Starship release-tar "starship:$STARSHIP_ARCHIVE:$STARSHIP_SHA256" - 'Verified official release archive to ~/.local/bin'
  else add_action install Starship github-release-tar starship - 'download verified Starship release from GitHub; check published SHA-256 digest'; fi
  plan_known_apt 'Zsh autosuggestions' zsh-autosuggestions ''
  plan_known_apt 'Zsh syntax highlighting' zsh-syntax-highlighting ''
  if has_command warp-terminal || package_installed warp-terminal; then
    add_action installed Warp none warp-terminal - 'Existing installation retained'
  else plan_repo_package Warp warp-terminal warp-terminal warp; fi
  if has_command ghostty || package_installed ghostty; then
    add_action installed Ghostty none ghostty - 'Existing installation retained'
  elif [[ $DISTRO == ubuntu && $BASE_CODENAME == resolute ]] && package_candidate ghostty; then
    plan_apt Ghostty ghostty ghostty
  else
    plan_manual Ghostty 'Official Ubuntu package starts at 26.04; other builds require explicit source choice: https://ghostty.org/docs/install/binary'
  fi
  add_action configure 'Zsh configuration' shell-zsh '' "$zsh_dep" 'Back up and replace managed block; load syntax highlighting last'
  local shell_config_dep=$((${#ACTION_TYPE[@]}-1))
  local zsh_path
  zsh_path=$(command -v zsh || printf /usr/bin/zsh)
  if [[ $(getent passwd "$(id -un)" | cut -d: -f7) == "$zsh_path" ]]; then
    add_action installed 'Default shell' none "$zsh_path" - 'Already configured'
  elif [[ ! -t 0 ]]; then
    plan_manual 'Default shell' "After Zsh configuration, run chsh -s $zsh_path in a terminal; password and new login may be required"
  else
    add_action configure 'Default shell' login-zsh "$zsh_path" "$shell_config_dep" 'chsh may prompt for account password; new login required'
  fi
}
