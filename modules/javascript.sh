#!/usr/bin/env bash
plan_mise_node() {
  local mise_dep=- node_dep=-
  if has_command mise || [[ -x $HOME/.local/bin/mise ]]; then
    add_action installed mise none mise - 'Existing installation retained'
  else
    local repo_index=${#ACTION_TYPE[@]}
    add_action configure 'mise repository' repo mise - 'sudo; extrepo official mise entry'
    mise_dep=$repo_index
    add_action install mise apt mise "$mise_dep" 'sudo apt-get install mise'
  fi
  if [[ -d $HOME/.local/share/mise/installs/node ]] && [[ -n $(find "$HOME/.local/share/mise/installs/node" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null) ]]; then
    add_action installed 'Node.js LTS via mise' none node - 'mise Node installation present; verify active version'
  else
    if [[ $mise_dep != - ]]; then node_dep=$((${#ACTION_TYPE[@]}-1)); fi
    add_action install 'Node.js LTS via mise' mise-tool node@lts "$node_dep" 'User install; no APT Node or NVM'
    node_dep=$((${#ACTION_TYPE[@]}-1))
  fi
  REPLY=$node_dep
}
plan_javascript() {
  plan_mise_node
  local node_dep=$REPLY tool
  for tool in pnpm bun; do
    if has_command "$tool"; then add_action installed "$tool" none "$tool" - 'Existing installation retained'
    else add_action install "$tool via mise" mise-tool "$tool@latest" "$node_dep" 'User install; projects may pin versions'; fi
  done
  if [[ -f $HOME/.bashrc ]] && grep -Fq '# linux-dev-setup managed block' "$HOME/.bashrc"; then
    add_action installed 'Bash mise activation' none '' - 'Managed block exists'
  else add_action configure 'Bash mise activation' shell-bash '' - 'Backup existing ~/.bashrc and append activation'; fi
  plan_note TypeScript 'Use project-local dev dependency: pnpm add -D typescript'
}
