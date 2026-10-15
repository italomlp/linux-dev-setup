#!/usr/bin/env bash
plan_terminal() {
  plan_apt Zsh zsh zsh
  plan_apt 'GNU Stow' stow stow
  plan_apt Zellij zellij zellij
  plan_apt Starship starship starship
  plan_apt 'Zsh autosuggestions' zsh-autosuggestions ''
  plan_apt 'Zsh syntax highlighting' zsh-syntax-highlighting ''
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
  if [[ -f $HOME/.zshrc ]] && grep -Fq '# linux-dev-setup managed block' "$HOME/.zshrc"; then
    add_action installed 'Zsh configuration' none '' - 'Managed block exists'
  else add_action configure 'Zsh configuration' shell-zsh '' - 'Backup existing ~/.zshrc, then append history, mise and Starship'; fi
  plan_manual 'Default shell' 'Run chsh -s /usr/bin/zsh after reviewing shell configuration'
}
