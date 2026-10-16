#!/usr/bin/env bash
APT_REFRESHED=0
refresh_apt() {
  if (( ! APT_REFRESHED )); then sudo apt-get update; APT_REFRESHED=1; fi
}
setup_repo() {
  local arch; arch=$(dpkg --print-architecture)
  case $1 in
    claude-desktop)
      local path=/etc/apt/sources.list.d/linux-dev-setup-claude-desktop.list key=/etc/apt/keyrings/linux-dev-setup-claude-desktop.asc
      [[ -e $path ]] && return 0
      local tmp; tmp=$(mktemp)
      curl -fsSL https://downloads.claude.ai/claude-desktop/key.asc -o "$tmp"
      local fingerprint
      fingerprint=$(gpg --show-keys --with-colons "$tmp" | awk -F: '$1=="fpr" {print $10; exit}')
      [[ $fingerprint == 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE ]] || { rm -f "$tmp"; echo 'Claude Desktop key mismatch' >&2; return 1; }
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      sudo install -m 644 "$tmp" "$key"
      printf 'deb [signed-by=%s] https://downloads.claude.ai/claude-desktop/apt/stable stable main\n' "$key" | sudo tee "$path" >/dev/null
      rm -f "$tmp"; APT_REFRESHED=0; refresh_apt;;
    warp)
      local path=/etc/apt/sources.list.d/linux-dev-setup-warp.list key=/etc/apt/keyrings/linux-dev-setup-warp.gpg
      # Warp's own installer commonly installs the same source and key under a
      # different path. Reuse that source instead of creating a conflicting
      # Signed-By entry for the same URI/suite.
      if repo_present warp; then
        return 0
      fi
      local tmp; tmp=$(mktemp)
      curl -fsSL https://releases.warp.dev/linux/keys/warp.asc -o "$tmp"
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      gpg --dearmor < "$tmp" | sudo tee "$key" >/dev/null
      sudo chmod 644 "$key"
      printf 'deb [arch=%s signed-by=%s] https://releases.warp.dev/linux/deb stable main\n' "$arch" "$key" | sudo tee "$path" >/dev/null
      rm -f "$tmp"; APT_REFRESHED=0; refresh_apt;;
    mise)
      sudo apt-get install -y extrepo
      sudo extrepo enable mise
      APT_REFRESHED=0; refresh_apt;;
    github-cli)
      local path=/etc/apt/sources.list.d/linux-dev-setup-github-cli.list
      [[ -e $path ]] && return 0
      local tmp; tmp=$(mktemp)
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.asc -o "$tmp"
      local fingerprints
      fingerprints=$(gpg --show-keys --with-colons "$tmp" | awk -F: '$1=="fpr" {print $10}')
      grep -Eq '2C6106201985B60E6C7AC87323F3D4EA75716059|7F38BBB59D064DBCB3D84D725612B36462313325' <<< "$fingerprints" || { rm -f "$tmp"; echo 'GitHub CLI key mismatch' >&2; return 1; }
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      gpg --dearmor < "$tmp" | sudo tee /etc/apt/keyrings/linux-dev-setup-github-cli.gpg >/dev/null
      sudo chmod 644 /etc/apt/keyrings/linux-dev-setup-github-cli.gpg
      printf 'deb [arch=%s signed-by=/etc/apt/keyrings/linux-dev-setup-github-cli.gpg] https://cli.github.com/packages stable main\n' "$arch" | sudo tee "$path" >/dev/null
      rm -f "$tmp"; APT_REFRESHED=0; refresh_apt;;
    docker)
      [[ $DISTRO == ubuntu || $DISTRO == debian ]] || return 1
      local path=/etc/apt/sources.list.d/linux-dev-setup-docker.sources key=/etc/apt/keyrings/linux-dev-setup-docker.asc
      [[ -e $path ]] && return 0
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      local tmp; tmp=$(mktemp)
      curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" -o "$tmp"
      local fingerprint
      fingerprint=$(gpg --show-keys --with-colons "$tmp" | awk -F: '$1=="fpr" {print $10; exit}')
      [[ $fingerprint == 9DC858229FC7DD38854AE2D88D81803C0EBFCD88 ]] || { rm -f "$tmp"; echo 'Docker key mismatch' >&2; return 1; }
      sudo install -m 644 "$tmp" "$key"; rm -f "$tmp"
      printf 'Types: deb\nURIs: https://download.docker.com/linux/%s\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: %s\n' "$DISTRO" "$BASE_CODENAME" "$arch" "$key" | sudo tee "$path" >/dev/null
      APT_REFRESHED=0; refresh_apt;;
    *) echo "Unknown repository: $1" >&2; return 1;;
  esac
}
append_shell_block() {
  local file=$1 block=$2 marker='# linux-dev-setup managed block'
  [[ -f $file ]] && grep -Fq "$marker" "$file" && return 0
  if [[ -f $file ]]; then cp -p "$file" "$file.backup.$(date +%Y%m%d-%H%M%S)"; fi
  { printf '\n%s\n' "$marker"; printf '%s\n' "$block"; printf '# end linux-dev-setup\n'; } >> "$file"
}
run_action() {
  local type=$1 arg=$2
  case $type in
    apt) refresh_apt; sudo apt-get install -y "$arg";;
    repo) setup_repo "$arg";;
    repo-tools) refresh_apt; sudo apt-get install -y ca-certificates curl gnupg;;
    flatpak)
      flatpak install --user -y flathub "$arg" || return
      flatpak info --user "$arg" >/dev/null 2>&1 || flatpak info "$arg" >/dev/null 2>&1;;
    flatpak-remote) flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo;;
    mise-tool) "$(command -v mise || printf '%s' "$HOME/.local/bin/mise")" use -g "$arg";;
    npm) "$(command -v mise || printf '%s' "$HOME/.local/bin/mise")" exec node@lts -- npm install -g "$arg";;
    shell-zsh) append_shell_block "$HOME/.zshrc" $'export PATH="$HOME/.local/bin:$PATH"\ncommand -v mise >/dev/null && eval "$(mise activate zsh)"\ncommand -v starship >/dev/null && eval "$(starship init zsh)"\nautoload -Uz compinit && compinit\n[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh\n[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\ncommand -v batcat >/dev/null && alias bat=batcat\ncommand -v fdfind >/dev/null && alias fd=fdfind\nalias gs="git status"\nalias dc="docker compose"\nHISTFILE="$HOME/.zsh_history"\nHISTSIZE=10000\nSAVEHIST=10000';;
    shell-bash) append_shell_block "$HOME/.bashrc" $'export PATH="$HOME/.local/bin:$PATH"\ncommand -v mise >/dev/null && eval "$(mise activate bash)"';;
    android-env) append_shell_block "$HOME/.profile" $'export ANDROID_HOME="$HOME/Android/Sdk"\nexport PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"';;
    *) echo "Unknown action type: $type" >&2; return 1;;
  esac
}
execute_plan() {
  local i failed=0 completed=0 skipped=0 dep
  for i in "${!ACTION_TYPE[@]}"; do
    [[ ${ACTION_STATUS[i]} == install || ${ACTION_STATUS[i]} == configure ]] || continue
    dep=${ACTION_DEP[i]}
    if [[ $dep != - && ${ACTION_RESULT[dep]} != done ]]; then
      ACTION_RESULT[i]=skipped; ((skipped+=1)); log_line "SKIP ${ACTION_TITLE[i]}: prerequisite failed"; continue
    fi
    log_line "START ${ACTION_TITLE[i]}"
    if run_action "${ACTION_TYPE[i]}" "${ACTION_ARG[i]}" >>"$LOG_FILE" 2>&1; then
      ACTION_RESULT[i]=done; ((completed+=1)); log_line "OK ${ACTION_TITLE[i]}"
    else
      ACTION_RESULT[i]=failed; ((failed+=1)); log_line "FAIL ${ACTION_TITLE[i]} (see log)"
    fi
  done
  printf '\nSummary: %d completed, %d failed, %d skipped.\n' "$completed" "$failed" "$skipped"
  (( failed == 0 ))
}
