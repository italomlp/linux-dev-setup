#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/lib/ui.sh"
ui_init
id=${1:-}
ui_heading 'Linux Dev Setup' "First-run setup · $id"
case $id in
  gh) echo 'GitHub CLI: checking authentication.'; gh auth status || gh auth login --web;;
  claude) echo 'Claude Code: checking authentication.'; claude auth status || claude auth login;;
  codex) echo 'Codex CLI: checking authentication.'; codex login status || codex login;;
  gemini) echo 'Gemini CLI: follow the sign-in prompts.'; gemini;;
  opencode) echo 'OpenCode: configure a provider through its authentication menu.'; opencode auth login;;
  agy) echo 'Antigravity CLI: follow its sign-in prompts.'; agy;;
  vscode-extension)
    source "$ROOT/lib/checklist.sh"
    checklist_marked vscode-account || { echo 'Review VS Code account setup in --checklist first.' >&2; exit 1; }
    if ! checklist_probed vscode-extension; then
      echo 'Installing Google Antigravity from the Visual Studio Marketplace.'
      code --install-extension google.google-antigravity
    fi
    checklist_probed vscode-extension || { echo 'Extension installation could not be verified.' >&2; exit 1; }
    echo 'To sign in to Antigravity, run agy in a terminal and complete its browser login.'
    echo 'Then run Developer: Reload Window in VS Code to use the shared login.';;
  tailscale) echo 'Tailscale: authenticate this machine in the browser.'; sudo tailscale up;;
  docker) echo 'Docker Desktop: start the user service, accept terms in the app, then check desktop-linux.'; systemctl --user start docker-desktop; docker --context desktop-linux info;;
  android) echo 'Android: the installer will download verified SDK tools, ask for Google license acceptance, and configure the SDK.'; bash "$ROOT/install.sh" --module android;;
  ollama) echo 'Ollama: choose a model yourself, then use ollama ps to inspect its backend.'; ollama ps;;
  restic) echo 'Restic: choose a backup destination and retention policy before initializing a repository.';;
  *) echo "Unknown checklist item: $id" >&2; exit 2;;
esac
printf '\n'; ui_style heading 'Press Enter to close this terminal... '
IFS= read -r _ || true
