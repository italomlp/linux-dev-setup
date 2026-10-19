#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
id=${1:-}
case $id in
  gh) echo 'GitHub CLI: checking authentication.'; gh auth status || gh auth login --web;;
  claude) echo 'Claude Code: checking authentication.'; claude auth status || claude auth login;;
  codex) echo 'Codex CLI: checking authentication.'; codex login status || codex login;;
  gemini) echo 'Gemini CLI: follow the sign-in prompts.'; gemini;;
  opencode) echo 'OpenCode: configure a provider through its authentication menu.'; opencode auth login;;
  agy) echo 'Antigravity CLI: follow its sign-in prompts.'; agy;;
  tailscale) echo 'Tailscale: authenticate this machine in the browser.'; sudo tailscale up;;
  docker) echo 'Docker Desktop: start the user service, accept terms in the app, then check desktop-linux.'; systemctl --user start docker-desktop; docker --context desktop-linux info;;
  android) echo 'Android: the installer will download verified SDK tools, ask for Google license acceptance, and configure the SDK.'; bash "$ROOT/install.sh" --module android;;
  ollama) echo 'Ollama: choose a model yourself, then use ollama ps to inspect its backend.'; ollama ps;;
  restic) echo 'Restic: choose a backup destination and retention policy before initializing a repository.';;
  *) echo "Unknown checklist item: $id" >&2; exit 2;;
esac
printf '\nPress Enter to close this terminal... '
IFS= read -r _ || true
