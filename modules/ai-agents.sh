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
  else plan_manual 'Antigravity CLI' 'Official Linux CLI installation exists; inspect https://codelabs.developers.google.com/antigravity-cli-hands-on and verify script before running'; fi
  if has_command claude-desktop || package_installed claude-desktop; then
    add_action installed 'Claude Desktop' none '' - 'Existing installation retained'
  elif is_native_distro && { [[ $DISTRO == ubuntu && ( $DISTRO_VERSION == 22.04 || $DISTRO_VERSION == 24.04 || $DISTRO_VERSION == 26.04 ) ]] || [[ $DISTRO == debian && ( $DISTRO_VERSION == 12 || $DISTRO_VERSION == 13 ) ]]; }; then
    plan_repo_package 'Claude Desktop' claude-desktop claude-desktop claude-desktop
  else plan_manual 'Claude Desktop' 'Official Linux beta supports Ubuntu 22.04+ and Debian 12+; derivatives are not formally supported: https://support.claude.com/en/articles/10065433-install-claude-desktop'; fi
  if has_command chatgpt || package_installed chatgpt; then
    add_action installed 'ChatGPT Desktop' none '' - 'Existing installation retained'
  elif [[ $DISTRO == ubuntu && ( $DISTRO_VERSION == 24.04 || $DISTRO_VERSION == 26.04 ) ]] || [[ $DISTRO == debian && $DISTRO_VERSION == 13 ]]; then
    plan_manual 'ChatGPT Desktop' 'Official Linux preview .deb for x64: https://learn.chatgpt.com/docs/linux/linux-app; download and sudo apt install ./chatgpt_amd64.deb'
  else plan_manual 'ChatGPT Desktop' 'Official Linux preview does not list this distribution/version: https://learn.chatgpt.com/docs/linux/linux-app'; fi
}
