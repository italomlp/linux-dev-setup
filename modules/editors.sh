#!/usr/bin/env bash
plan_editors() {
  plan_apt Vim vim vim
  if has_command code || package_installed code; then
    add_action installed 'Visual Studio Code' none code - 'Existing installation retained; account and Antigravity extension setup are in --checklist'
  else
    add_action install 'Visual Studio Code' vscode-deb '' - 'Official Microsoft .deb; validate package/architecture; allow package-managed signed APT updates; desktop and vscode:// handlers supplied by package; follow --checklist for sign-in and extension'
  fi
}
