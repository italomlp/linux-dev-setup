#!/usr/bin/env bash
CHECKLIST_IDS=()
CHECKLIST_NAMES=()
CHECKLIST_KINDS=()
checklist_add() { CHECKLIST_IDS+=("$1"); CHECKLIST_NAMES+=("$2"); CHECKLIST_KINDS+=("$3"); }
checklist_catalog() {
  CHECKLIST_IDS=(); CHECKLIST_NAMES=(); CHECKLIST_KINDS=()
  has_command gh && checklist_add gh 'GitHub CLI' cli
  has_command claude && checklist_add claude 'Claude Code' cli
  has_command codex && checklist_add codex 'Codex CLI' cli
  has_command gemini && checklist_add gemini 'Gemini CLI' cli
  has_command opencode && checklist_add opencode 'OpenCode' cli
  has_command agy && checklist_add agy 'Antigravity CLI' cli
  has_command tailscale && checklist_add tailscale Tailscale cli
  { package_installed docker-desktop || has_command docker; } && checklist_add docker 'Docker Desktop' cli
  { [[ -x $HOME/.local/share/android-studio/bin/studio ]] || [[ -x /opt/android-studio/bin/studio ]]; } && checklist_add android 'Android Studio and SDK' cli
  has_command ollama && checklist_add ollama Ollama cli
  has_command restic && checklist_add restic Restic cli
  has_command warp-terminal && checklist_add warp Warp gui
  has_command claude-desktop && checklist_add claude-desktop 'Claude Desktop' gui
  { has_command chatgpt || package_installed chatgpt; } && checklist_add chatgpt 'ChatGPT Desktop' gui
  { has_command antigravity-ide || [[ -x $HOME/.local/share/antigravity-ide/antigravity-ide ]]; } && checklist_add antigravity-ide 'Antigravity IDE' gui
  has_command slack && checklist_add slack Slack gui
  has_command dbeaver && checklist_add dbeaver DBeaver gui
  has_command bruno && checklist_add bruno Bruno gui
  has_command google-chrome && checklist_add chrome 'Google Chrome' gui
  has_command vivaldi && checklist_add vivaldi Vivaldi gui
  { has_command zen || has_command zen-bin || flatpak_installed app.zen_browser.zen; } && checklist_add zen 'Zen Browser' gui
  return 0
}
checklist_state_file() { printf '%s' "$HOME/.local/state/linux-dev-setup/checklist.done"; }
checklist_marked() { [[ -f $(checklist_state_file) ]] && grep -Fxq "$1" "$(checklist_state_file)"; }
checklist_mark() {
  local file; file=$(checklist_state_file)
  mkdir -p "${file%/*}"
  chmod 700 "${file%/*}"
  touch "$file"; chmod 600 "$file"
  checklist_marked "$1" || printf '%s\n' "$1" >> "$file"
}
checklist_detail() {
  case $1 in
    gh) printf 'Verify GitHub authentication; open a terminal for browser login only if needed.';;
    claude) printf 'Verify Claude Code authentication; open a terminal for Anthropic sign-in only if needed.';;
    codex) printf 'Verify Codex CLI authentication; open a terminal for ChatGPT sign-in only if needed.';;
    gemini) printf 'Open Gemini CLI and complete its account sign-in prompts.';;
    opencode) printf 'Open OpenCode provider authentication in a terminal.';;
    agy) printf 'Open Antigravity CLI and complete its sign-in prompts.';;
    tailscale) printf 'Run Tailscale login in a terminal and authorize this machine in the browser.';;
    docker) printf 'Start Docker Desktop, accept its terms, then verify the desktop-linux context and daemon.';;
    android) printf 'Run the Android module for verified SDK downloads and license prompts; then review Studio setup.';;
    ollama) printf 'Inspect Ollama; choose a model yourself before checking its inference backend.';;
    restic) printf 'Choose a backup destination and retention policy before initializing Restic.';;
    warp) printf 'Launch Warp for its optional account and terminal preferences.';;
    claude-desktop) printf 'Launch Claude Desktop to sign in and review first-run settings.';;
    chatgpt) printf 'Launch ChatGPT Desktop to sign in and review first-run settings.';;
    antigravity-ide) printf 'Launch Antigravity IDE to sign in and finish IDE preferences.';;
    slack) printf 'Launch Slack and sign in to a workspace.';;
    dbeaver) printf 'Launch DBeaver and configure connections only if needed.';;
    bruno) printf 'Launch Bruno and review optional collections or account setup.';;
    chrome|vivaldi)
      printf 'Optional profile and account sync review; launch browser, with no scripted login or default-browser change.'
      local repo=$1
      [[ $repo != chrome ]] || repo=google-chrome
      if [[ -f $(apt_source_dir)/linux-dev-setup-$repo.list ]] && vendor_repo_valid "$repo"; then
        printf ' The applications module also plans to back up and remove the redundant installer APT source.'
      fi;;
    zen) printf 'Optional profile and account sync review; launch browser, with no scripted login or default-browser change.';;
  esac
}
checklist_probed() {
  case $1 in
    gh) gh auth status >/dev/null 2>&1;;
    claude) claude auth status 2>/dev/null | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("loggedIn") is True else 1)' 2>/dev/null;;
    codex) codex login status >/dev/null 2>&1;;
    tailscale) tailscale status >/dev/null 2>&1;;
    docker) docker context inspect desktop-linux >/dev/null 2>&1 && docker --context desktop-linux info >/dev/null 2>&1;;
    android)
      local sdk; sdk=$(sdk_directory) || return 1
      [[ -d $sdk/platforms && -n $(find "$sdk/platforms" -mindepth 1 -maxdepth 1 -type d -print -quit) && -d $sdk/build-tools && -n $(find "$sdk/build-tools" -mindepth 1 -maxdepth 1 -type d -print -quit) ]];;
    *) return 2;;
  esac
}
checklist_status() {
  local id=$1 dry=$2
  if checklist_probed "$id"; then printf ready; return; fi
  if [[ $id == codex && $dry == 1 && -s $HOME/.codex/auth.json ]]; then printf 'signed in locally (unverified)'; return; fi
  case $id in
    gh)
      if [[ -s $HOME/.config/gh/hosts.yml ]] && grep -q 'oauth_token:' "$HOME/.config/gh/hosts.yml"; then
        printf 'configured (verification unavailable)'
      else printf pending; fi;;
    claude|codex|tailscale|docker|android) printf pending;;
    *) if checklist_marked "$id"; then printf marked; else printf review; fi;;
  esac
}
checklist_launch() {
  local id=$1 kind=$2
  if [[ $kind == cli ]]; then
    if has_command x-terminal-emulator; then
      x-terminal-emulator -e "$ROOT/scripts/checklist-terminal.sh" "$id" || return 1
    else
      bash "$ROOT/scripts/checklist-terminal.sh" "$id"
    fi
  else
    case $id in
      warp) warp-terminal >/dev/null 2>&1 &;;
      claude-desktop) claude-desktop >/dev/null 2>&1 &;;
      chatgpt) chatgpt >/dev/null 2>&1 &;;
      antigravity-ide) if has_command antigravity-ide; then antigravity-ide >/dev/null 2>&1 & else "${HOME}/.local/share/antigravity-ide/antigravity-ide" >/dev/null 2>&1 & fi;;
      slack) slack >/dev/null 2>&1 &;;
      dbeaver) dbeaver >/dev/null 2>&1 &;;
      bruno) bruno >/dev/null 2>&1 &;;
      chrome) google-chrome >/dev/null 2>&1 &;;
      vivaldi) vivaldi >/dev/null 2>&1 &;;
      zen) if has_command zen; then zen >/dev/null 2>&1 & elif has_command zen-bin; then zen-bin >/dev/null 2>&1 & else flatpak run app.zen_browser.zen >/dev/null 2>&1 & fi;;
      *) return 1;;
    esac
  fi
}
run_checklist() {
  local dry=$1 i choice id kind state answer
  checklist_catalog
  printf 'Guided setup checklist\n'
  while true; do
    for i in "${!CHECKLIST_IDS[@]}"; do
      state=$(checklist_status "${CHECKLIST_IDS[i]}" "$dry")
      printf '%2d) %-26s %s\n' "$((i+1))" "${CHECKLIST_NAMES[i]}" "$state"
      printf '    %s\n' "$(checklist_detail "${CHECKLIST_IDS[i]}")"
    done
    (( dry )) && return 0
    [[ -t 0 ]] || { echo 'Interactive checklist requires a terminal; use --checklist --dry-run for status' >&2; return 2; }
    printf 'Choose an item (0 to exit): '
    IFS= read -r choice || return 0
    [[ $choice == 0 ]] && return 0
    [[ $choice =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#CHECKLIST_IDS[@]} )) || { echo 'Invalid selection'; continue; }
    id=${CHECKLIST_IDS[choice-1]}; kind=${CHECKLIST_KINDS[choice-1]}
    checklist_launch "$id" "$kind" || { echo "Could not launch ${CHECKLIST_NAMES[choice-1]}"; continue; }
    printf 'Complete setup in the opened app or terminal, then press Enter to recheck: '
    IFS= read -r answer || return 0
    state=$(checklist_status "$id" 0)
    if [[ $state != ready ]] && ! checklist_probed "$id"; then
      case $id in gh|claude|codex|tailscale|docker|android) echo 'Still pending according to the tool';;
        *) printf 'No reliable status check. Mark this item complete? [y/N] '; IFS= read -r answer || return 0; [[ $answer == y || $answer == Y ]] && checklist_mark "$id";;
      esac
    fi
  done
}
