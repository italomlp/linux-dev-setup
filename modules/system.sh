#!/usr/bin/env bash
plan_system() {
  source "$ROOT/config/packages.conf"
  local item title package binary
  for item in "${SYSTEM_PACKAGES[@]}"; do
    IFS=: read -r title package binary <<< "$item"
    plan_apt "$title" "$package" "$binary"
  done
  if has_command gh; then add_action installed 'GitHub CLI' none gh - 'Existing installation retained'
  else plan_repo_package 'GitHub CLI' gh gh github-cli; fi
  if has_command lazygit; then add_action installed Lazygit none lazygit - 'Existing installation retained'
  elif package_candidate lazygit; then plan_apt Lazygit lazygit lazygit
  else plan_manual Lazygit 'No APT candidate; use reviewed official release with checksum: https://github.com/jesseduffield/lazygit/releases'; fi
}
