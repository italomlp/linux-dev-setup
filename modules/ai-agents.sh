#!/usr/bin/env bash
plan_ai_agents() {
  add_action configure 'AI CLI command path' ai-path '' - 'Back up Bash/Zsh config; keep ~/.local/bin ahead of project tool paths'
  local path_dep=$((${#ACTION_TYPE[@]}-1))
  local binary title
  for binary in claude codex opencode gemini; do
    case $binary in claude) title='Claude Code';; codex) title='OpenAI Codex CLI';; opencode) title=OpenCode;; gemini) title='Gemini CLI';; esac
    add_action install "$title" ai-cli "$binary" "$path_dep" 'Verify stable user installation; migrate old mise npm copies only after success; Gemini uses active Node'
  done
  if has_command agy; then add_action installed 'Antigravity CLI' none '' - 'Existing installation retained'
  else add_action install 'Antigravity CLI' antigravity-cli '' - 'download verified Antigravity CLI using vendor SHA-512 manifest'; fi
  if has_command claude-desktop || package_installed claude-desktop; then
    add_action installed 'Claude Desktop' none '' - 'Existing installation retained'
  elif { is_ubuntu_based && [[ $(ubuntu_compat_version) == 22.04 || $(ubuntu_compat_version) == 24.04 || $(ubuntu_compat_version) == 26.04 ]]; } || { [[ $DISTRO == debian && ( $DISTRO_VERSION == 12 || $DISTRO_VERSION == 13 ) ]]; }; then
    plan_repo_package 'Claude Desktop' claude-desktop claude-desktop claude-desktop
  else plan_manual 'Claude Desktop' 'Official Linux beta supports Ubuntu 22.04+ and Debian 12+; derivatives are not formally supported: https://support.claude.com/en/articles/10065433-install-claude-desktop'; fi
  if has_command chatgpt || package_installed chatgpt; then
    add_action installed 'ChatGPT Desktop' none '' - 'Existing installation retained'
  elif { is_ubuntu_based && [[ $(ubuntu_compat_version) == 24.04 || $(ubuntu_compat_version) == 26.04 ]]; } || [[ $DISTRO == debian && $DISTRO_VERSION == 13 ]]; then
    add_action install 'ChatGPT Desktop' chatgpt-deb '' - 'download official ChatGPT .deb over HTTPS; validate package metadata; install with APT (no published checksum)'
  else plan_manual 'ChatGPT Desktop' 'Official Linux preview does not list this distribution/version: https://learn.chatgpt.com/docs/linux/linux-app'; fi
}
