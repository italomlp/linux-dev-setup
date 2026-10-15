#!/usr/bin/env bash
plan_editors() {
  plan_apt Vim vim vim
  if has_command antigravity || package_installed antigravity; then
    add_action installed 'Google Antigravity' none '' - 'Existing installation retained'
  else
    plan_manual 'Google Antigravity' 'Download official Linux package from https://antigravity.google/download and verify the published artifact before installation'
  fi
}
