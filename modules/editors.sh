#!/usr/bin/env bash
plan_editors() {
  plan_apt Vim vim vim
  local ide_path=''
  if has_command antigravity-ide; then ide_path=$(command -v antigravity-ide); fi
  if has_command antigravity || package_installed antigravity || [[ -x $HOME/.local/share/antigravity-ide/antigravity-ide ]] || { [[ -n $ide_path && $ide_path != "$HOME/.local/bin/antigravity-ide" ]]; }; then
    add_action installed 'Google Antigravity' none '' - 'Existing installation retained'
  else
    add_action install 'Google Antigravity IDE' antigravity-ide '' - 'download official Antigravity IDE Linux tarball over HTTPS; no vendor checksum is published'
  fi
}
