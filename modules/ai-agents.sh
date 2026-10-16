#!/usr/bin/env bash
plan_ai_agents() {
  local node_dep=-
  local i
  for i in "${!ACTION_TITLE[@]}"; do
    if [[ ${ACTION_TITLE[i]} == 'Node.js LTS via mise' && ${ACTION_STATUS[i]} == install ]]; then node_dep=$i; fi
  done
  if [[ $node_dep == - ]] && { ! has_command mise || [[ ! -d $HOME/.local/share/mise/installs/node ]]; }; then
    source "$ROOT/modules/javascript.sh"
    plan_mise_node
    node_dep=$REPLY
  fi
  local items=('Claude Code:claude:@anthropic-ai/claude-code' 'OpenAI Codex CLI:codex:@openai/codex' 'OpenCode:opencode:@opencode/cli' 'Gemini CLI:gemini:@google/gemini-cli') item title binary package
  for item in "${items[@]}"; do
    IFS=: read -r title binary package <<< "$item"
    if has_command "$binary"; then add_action installed "$title" none "$binary" - 'Existing installation retained'
    else add_action install "$title" npm "$package" "$node_dep" 'User-level npm via mise; no automatic login'; fi
  done
  if has_command agy || has_command agy-ide; then add_action installed 'Antigravity CLI' none '' - 'Existing installation retained'
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
