#!/usr/bin/env bash
APT_REFRESHED=0
refresh_apt() {
  if (( ! APT_REFRESHED )); then sudo apt-get update || return 1; APT_REFRESHED=1; fi
}
setup_repo() {
  local arch; arch=$(dpkg --print-architecture)
  case $1 in
    claude-desktop)
      local path=/etc/apt/sources.list.d/linux-dev-setup-claude-desktop.list key=/etc/apt/keyrings/linux-dev-setup-claude-desktop.asc
      if [[ -e /etc/apt/sources.list.d/claude-desktop.list ]]; then
        [[ ! -e $path ]] || sudo rm -f "$path"
        APT_REFRESHED=0
        refresh_apt
        return 0
      fi
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
      local docker_distro=$DISTRO
      [[ $DISTRO == linuxmint ]] && docker_distro=ubuntu
      [[ $docker_distro == ubuntu || $docker_distro == debian ]] || return 1
      local path=/etc/apt/sources.list.d/linux-dev-setup-docker.sources key=/etc/apt/keyrings/linux-dev-setup-docker.asc
      [[ -e $path ]] && return 0
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      local tmp; tmp=$(mktemp)
      curl -fsSL "https://download.docker.com/linux/$docker_distro/gpg" -o "$tmp"
      local fingerprint
      fingerprint=$(gpg --show-keys --with-colons "$tmp" | awk -F: '$1=="fpr" {print $10; exit}')
      [[ $fingerprint == 9DC858229FC7DD38854AE2D88D81803C0EBFCD88 ]] || { rm -f "$tmp"; echo 'Docker key mismatch' >&2; return 1; }
      sudo install -m 644 "$tmp" "$key"; rm -f "$tmp"
      printf 'Types: deb\nURIs: https://download.docker.com/linux/%s\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: %s\n' "$docker_distro" "$BASE_CODENAME" "$arch" "$key" | sudo tee "$path" >/dev/null
      APT_REFRESHED=0; refresh_apt;;
    tailscale)
      local path=/etc/apt/sources.list.d/linux-dev-setup-tailscale.list key=/usr/share/keyrings/tailscale-archive-keyring.gpg
      repo_present tailscale && return 0
      [[ $BASE_CODENAME == noble || $BASE_CODENAME == jammy || $BASE_CODENAME == resolute ]] || return 1
      local tmp; tmp=$(mktemp)
      curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/$BASE_CODENAME.noarmor.gpg" -o "$tmp"
      gpg --show-keys "$tmp" >/dev/null
      sudo install -d -m 755 /usr/share/keyrings /etc/apt/sources.list.d
      sudo install -m 644 "$tmp" "$key"; rm -f "$tmp"
      printf 'deb [signed-by=%s] https://pkgs.tailscale.com/stable/ubuntu %s main\n' "$key" "$BASE_CODENAME" | sudo tee "$path" >/dev/null
      APT_REFRESHED=0; refresh_apt;;
    google-chrome)
      local path=/etc/apt/sources.list.d/linux-dev-setup-google-chrome.list key=/etc/apt/keyrings/linux-dev-setup-google-chrome.asc
      repo_present google-chrome && return 0
      local tmp; tmp=$(mktemp)
      curl -fsSL https://dl.google.com/linux/linux_signing_key.pub -o "$tmp"
      gpg --show-keys --with-colons "$tmp" | awk -F: '$1=="fpr" {print $10}' | grep -qx EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796 || { rm -f "$tmp"; echo 'Google Chrome key mismatch' >&2; return 1; }
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      sudo install -m 644 "$tmp" "$key"; rm -f "$tmp"
      printf 'deb [arch=amd64 signed-by=%s] https://dl.google.com/linux/chrome/deb/ stable main\n' "$key" | sudo tee "$path" >/dev/null
      APT_REFRESHED=0; refresh_apt;;
    vivaldi)
      local path=/etc/apt/sources.list.d/linux-dev-setup-vivaldi.list key=/etc/apt/keyrings/linux-dev-setup-vivaldi.gpg
      repo_present vivaldi && return 0
      local tmp; tmp=$(mktemp)
      curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub -o "$tmp"
      gpg --show-keys "$tmp" >/dev/null
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      gpg --dearmor < "$tmp" | sudo tee "$key" >/dev/null
      sudo chmod 644 "$key"; rm -f "$tmp"
      printf 'deb [arch=%s signed-by=%s] https://repo.vivaldi.com/archive/deb/ stable main\n' "$arch" "$key" | sudo tee "$path" >/dev/null
      APT_REFRESHED=0; refresh_apt;;
    dbeaver)
      local path=/etc/apt/sources.list.d/linux-dev-setup-dbeaver.list key=/etc/apt/keyrings/linux-dev-setup-dbeaver.gpg
      repo_present dbeaver && return 0
      local tmp; tmp=$(mktemp)
      curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key -o "$tmp" || { rm -f "$tmp"; return 1; }
      gpg --show-keys "$tmp" >/dev/null || { rm -f "$tmp"; return 1; }
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      gpg --dearmor < "$tmp" | sudo tee "$key" >/dev/null || { rm -f "$tmp"; return 1; }
      sudo chmod 644 "$key"; rm -f "$tmp"
      printf 'deb [arch=%s signed-by=%s] https://dbeaver.io/debs/dbeaver-ce /\n' "$arch" "$key" | sudo tee "$path" >/dev/null
      APT_REFRESHED=0; refresh_apt;;
    bruno)
      local path=/etc/apt/sources.list.d/linux-dev-setup-bruno.list key=/etc/apt/keyrings/linux-dev-setup-bruno.gpg
      repo_present bruno && return 0
      local tmp; tmp=$(mktemp)
      curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9FA6017ECABE0266' -o "$tmp" || { rm -f "$tmp"; return 1; }
      gpg --show-keys --with-colons "$tmp" | awk -F: '$1=="pub" {print toupper($5); exit}' | grep -q '9FA6017ECABE0266$' || { rm -f "$tmp"; echo 'Bruno repository key ID mismatch' >&2; return 1; }
      sudo install -d -m 755 /etc/apt/keyrings /etc/apt/sources.list.d
      gpg --dearmor < "$tmp" | sudo tee "$key" >/dev/null || { rm -f "$tmp"; return 1; }
      sudo chmod 644 "$key"; rm -f "$tmp"
      printf 'deb [arch=%s signed-by=%s] http://debian.usebruno.com/ bruno stable\n' "$arch" "$key" | sudo tee "$path" >/dev/null
      APT_REFRESHED=0; refresh_apt;;
    slack-signature)
      local origin=F3DDF3571F28FFDE key=/usr/share/debsig/keyrings/F3DDF3571F28FFDE/debsig.gpg policy=/etc/debsig/policies/F3DDF3571F28FFDE/slack.pol tmp key_id
      if [[ -f $policy && -s $key ]]; then return 0; fi
      tmp=$(mktemp)
      curl -fsSL https://slack.com/gpg/slack_pubkey_20251016.gpg -o "$tmp" || { rm -f "$tmp"; return 1; }
      key_id=$(gpg --show-keys --with-colons "$tmp" | awk -F: '$1=="pub" {print toupper($5); exit}')
      [[ $key_id == "$origin" ]] || { rm -f "$tmp"; echo 'Slack signature key ID mismatch' >&2; return 1; }
      sudo install -d -m 755 "${key%/*}" "${policy%/*}" || { rm -f "$tmp"; return 1; }
      sudo touch "$key" || { rm -f "$tmp"; return 1; }
      sudo gpg --batch --no-default-keyring --keyring "$key" --import "$tmp" || { rm -f "$tmp"; return 1; }
      sudo chmod 644 "$key" || { rm -f "$tmp"; return 1; }
      cat > "$tmp.policy" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE Policy SYSTEM "https://www.debian.org/debsig/1.0/policy.dtd">
<Policy xmlns="https://www.debian.org/debsig/1.0/">
  <Origin Name="Slack" id="F3DDF3571F28FFDE" Description="Slack"/>
  <Selection>
    <Required Type="origin" File="debsig.gpg" id="F3DDF3571F28FFDE"/>
  </Selection>
  <Verification>
    <Required Type="origin" File="debsig.gpg" id="F3DDF3571F28FFDE"/>
  </Verification>
</Policy>
EOF
      sudo install -m 644 "$tmp.policy" "$policy" || { rm -f "$tmp" "$tmp.policy"; return 1; }
      rm -f "$tmp" "$tmp.policy";;
    *) echo "Unknown repository: $1" >&2; return 1;;
  esac
}
append_shell_block() {
  local file=$1 block=$2 marker='# linux-dev-setup managed block'
  [[ -f $file ]] && grep -Fq "$marker" "$file" && return 0
  if [[ -f $file ]]; then cp -p "$file" "$file.backup.$(date +%Y%m%d-%H%M%S)"; fi
  { printf '\n%s\n' "$marker"; printf '%s\n' "$block"; printf '# end linux-dev-setup\n'; } >> "$file"
}
replace_shell_block() {
  local file=$1 block=$2 tmp
  tmp=$(mktemp)
  if [[ -f $file ]]; then
    cp -p "$file" "$file.backup.$(date +%Y%m%d-%H%M%S)"
    awk '/^# linux-dev-setup managed block$/{skip=1;next} /^# end linux-dev-setup$/{skip=0;next} !skip{print}' "$file" > "$tmp"
  fi
  { cat "$tmp"; printf '\n# linux-dev-setup managed block\n%s\n# end linux-dev-setup\n' "$block"; } > "$file"
  rm -f "$tmp"
}
zsh_plugins_ready() {
  [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] || { echo 'zsh-autosuggestions package script is missing' >&2; return 1; }
  [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] || { echo 'zsh-syntax-highlighting package script is missing' >&2; return 1; }
}
repair_claude_repo() {
  local package_source=/etc/apt/sources.list.d/claude-desktop.list installer_source=/etc/apt/sources.list.d/linux-dev-setup-claude-desktop.list
  if [[ -e $package_source && -e $installer_source ]]; then
    sudo rm -f "$installer_source"
    APT_REFRESHED=0
    refresh_apt
  fi
}
run_action() {
  local type=$1 arg=$2
  case $type in
    apt)
      refresh_apt || return 1
      sudo apt-get install -y "$arg" || return
      [[ $arg != claude-desktop ]] || repair_claude_repo;;
    claude-repo-repair) repair_claude_repo;;
    repo) setup_repo "$arg";;
    slack-signature) setup_repo slack-signature;;
    slack-deb)
      (
        set -Eeuo pipefail
        local tmp deb url
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        deb="$tmp/slack-desktop-amd64.deb"
        curl -fsSL --retry 3 'https://slack.com/downloads/instructions/linux?ddl=1&build=deb' -o "$tmp/slack.html" || return 1
        url=$(python3 "$ROOT/scripts/resolve-download.py" slack-deb "$tmp/slack.html") || return 1
        curl -fsSL --retry 3 "$url" -o "$deb" || return 1
        [[ $(dpkg-deb -f "$deb" Package) == slack-desktop ]] || return 1
        [[ $(dpkg-deb -f "$deb" Architecture) == amd64 ]] || return 1
        debsig-verify "$deb" || return 1
        sha256sum "$deb"
        refresh_apt || return 1
        sudo apt-get install -y "$deb" || return 1
        has_command slack || return 1
      );;
    repo-tools) refresh_apt; sudo apt-get install -y ca-certificates curl gnupg;;
    flatpak)
      flatpak install --user -y flathub "$arg" || return
      flatpak info --user "$arg" >/dev/null 2>&1 || flatpak info "$arg" >/dev/null 2>&1;;
    flatpak-remote) flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo;;
    mise-tool) "$(command -v mise || printf '%s' "$HOME/.local/bin/mise")" use -g "$arg";;
    npm) "$(command -v mise || printf '%s' "$HOME/.local/bin/mise")" exec node@lts -- npm install -g "$arg";;
    shell-zsh)
      zsh_plugins_ready || return 1
      replace_shell_block "$HOME/.zshrc" $'export PATH="$HOME/.local/bin:$PATH"\ncommand -v mise >/dev/null && eval "$(mise activate zsh)"\ncommand -v starship >/dev/null && eval "$(starship init zsh)"\nautoload -Uz compinit && compinit\n[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh\ncommand -v batcat >/dev/null && alias bat=batcat\ncommand -v fdfind >/dev/null && alias fd=fdfind\nalias gs="git status"\nalias dc="docker compose"\nHISTFILE="$HOME/.zsh_history"\nHISTSIZE=10000\nSAVEHIST=10000\n[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
      zsh -n "$HOME/.zshrc";;
    shell-bash) append_shell_block "$HOME/.bashrc" $'export PATH="$HOME/.local/bin:$PATH"\ncommand -v mise >/dev/null && eval "$(mise activate bash)"';;
    android-env)
      replace_shell_block "$HOME/.profile" "export ANDROID_HOME=\"$arg\""$'\nexport PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"';;
    android-studio)
      (
        set -Eeuo pipefail
        local archive=$arg sha=${ANDROID_STUDIO_SHA256:-} tmp='' url name
        if [[ $arg == auto ]]; then
          tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
          curl -fsSL --retry 3 https://developer.android.com/studio -o "$tmp/studio.html"
          IFS=$'\t' read -r url sha name < <(python3 "$ROOT/scripts/resolve-download.py" android "$tmp/studio.html")
          [[ -n $url && $sha =~ ^[0-9a-f]{64}$ && -n $name ]] || return 1
          archive="$tmp/$name"
          curl -fsSL --retry 3 "$url" -o "$archive"
        fi
        [[ -f $archive && $archive == *.tar.gz && $sha =~ ^[[:xdigit:]]{64}$ ]] || return 1
        printf '%s  %s\n' "$sha" "$archive" | sha256sum -c -
        tar -tzf "$archive" | grep -Fx 'android-studio/bin/studio' >/dev/null
        mkdir -p "$HOME/.local/share"
        tar -xzf "$archive" -C "$HOME/.local/share"
        "$HOME/.local/share/android-studio/bin/studio" >/dev/null 2>&1 &
      );;
    login-zsh)
      [[ -x $arg ]] || return 1
      zsh -n "$HOME/.zshrc"
      if [[ ! -t 0 || ! -w /dev/tty ]]; then echo 'Run chsh interactively to set Zsh as default shell' >&2; return 0; fi
      printf 'Changing the login shell to %s. Enter your account password if prompted.\n' "$arg" >/dev/tty
      chsh -s "$arg" </dev/tty >/dev/tty 2>&1;;
    docker-desktop)
      has_kvm && kvm_access || { echo 'KVM access is pending; sign out and back in, then rerun' >&2; return 3; }
      if [[ $arg == auto ]]; then
        (
          set -Eeuo pipefail
          local tmp url sha
          tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
          curl -fsSL --retry 3 https://docs.docker.com/desktop/release-notes/ -o "$tmp/notes.html"
          url=$(python3 "$ROOT/scripts/resolve-download.py" docker-url "$tmp/notes.html")
          curl -fsSL --retry 3 "${url%/*}/checksums.txt" -o "$tmp/checksums.txt"
          sha=$(python3 "$ROOT/scripts/resolve-download.py" docker-checksum "$tmp/checksums.txt")
          curl -fsSL --retry 3 "$url" -o "$tmp/docker-desktop-amd64.deb"
          printf '%s  %s\n' "$sha" "$tmp/docker-desktop-amd64.deb" | sha256sum -c -
          refresh_apt; sudo apt-get install -y "$tmp/docker-desktop-amd64.deb"
        )
      else
        [[ -f $arg && $arg == *.deb && ${DOCKER_DESKTOP_SHA256:-} =~ ^[[:xdigit:]]{64}$ ]] || return 1
        printf '%s  %s\n' "$DOCKER_DESKTOP_SHA256" "$arg" | sha256sum -c -
        refresh_apt; sudo apt-get install -y "$arg"
      fi
      package_installed docker-desktop && docker --version && docker compose version;;
    chatgpt-deb)
      (
        set -Eeuo pipefail
        local tmp url
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fsSL --retry 3 https://learn.chatgpt.com/docs/linux/linux-app -o "$tmp/download.html"
        url=$(python3 "$ROOT/scripts/resolve-download.py" chatgpt "$tmp/download.html")
        curl -fsSL --retry 3 "$url" -o "$tmp/chatgpt_amd64.deb"
        [[ $(dpkg-deb -f "$tmp/chatgpt_amd64.deb" Package) == chatgpt || $(dpkg-deb -f "$tmp/chatgpt_amd64.deb" Package) == chatgpt-desktop ]]
        [[ $(dpkg-deb -f "$tmp/chatgpt_amd64.deb" Architecture) == amd64 ]]
        sha256sum "$tmp/chatgpt_amd64.deb"
        refresh_apt; sudo apt-get install -y "$tmp/chatgpt_amd64.deb"
        has_command chatgpt
      );;
    antigravity-ide)
      (
        set -Eeuo pipefail
        local tmp url target response_kind
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fsSL --compressed --retry 3 https://antigravity.google/download -o "$tmp/download" || return 1
        response_kind=$(python3 "$ROOT/scripts/resolve-download.py" antigravity-response "$tmp/download") || return 1
        if [[ $response_kind == archive ]]; then
          mv "$tmp/download" "$tmp/antigravity-ide.tar.gz"
        else
          if [[ $response_kind == html-gzip ]]; then
            gzip -cd "$tmp/download" > "$tmp/download.html" || return 1
          else
            mv "$tmp/download" "$tmp/download.html"
          fi
          url=$(python3 "$ROOT/scripts/resolve-download.py" antigravity-ide "$tmp/download.html") || return 1
          [[ -n $url ]] || return 1
          curl -fsSL --retry 3 "$url" -o "$tmp/antigravity-ide.tar.gz" || return 1
        fi
        python3 "$ROOT/scripts/resolve-download.py" tar-root "$tmp/antigravity-ide.tar.gz" 'Antigravity IDE' || return 1
        tar -tzf "$tmp/antigravity-ide.tar.gz" | grep -Fx 'Antigravity IDE/antigravity-ide' >/dev/null || return 1
        target="$HOME/.local/share/antigravity-ide"
        [[ ! -e $target ]] || return 1
        tar -xzf "$tmp/antigravity-ide.tar.gz" -C "$tmp" || return 1
        mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
        mv "$tmp/Antigravity IDE" "$target" || return 1
        printf '#!/usr/bin/env bash\nexec "%s/antigravity-ide" "$@"\n' "$target" > "$HOME/.local/bin/antigravity-ide"
        chmod 755 "$HOME/.local/bin/antigravity-ide"
        [[ -x $target/antigravity-ide ]]
      );;
    antigravity-cli)
      (
        set -Eeuo pipefail
        local tmp url sha
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fsSL --retry 3 https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json -o "$tmp/manifest.json"
        IFS=$'\t' read -r url sha < <(python3 "$ROOT/scripts/resolve-download.py" antigravity-cli "$tmp/manifest.json")
        [[ -n $url && $sha =~ ^[0-9a-f]{128}$ ]] || return 1
        curl -fsSL --retry 3 "$url" -o "$tmp/agy.tar.gz"
        printf '%s  %s\n' "$sha" "$tmp/agy.tar.gz" | sha512sum -c -
        tar -tzf "$tmp/agy.tar.gz" | grep -Fx antigravity >/dev/null
        tar -xOzf "$tmp/agy.tar.gz" antigravity > "$tmp/agy"
        mkdir -p "$HOME/.local/bin"
        install -m 755 "$tmp/agy" "$HOME/.local/bin/agy"
        "$HOME/.local/bin/agy" --version
      );;
    llama-vulkan)
      (
        set -Eeuo pipefail
        local tmp url sha name tag root
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fsSL --retry 3 'https://api.github.com/repos/ggml-org/llama.cpp/releases?per_page=20' -o "$tmp/releases.json"
        IFS=$'\t' read -r url sha name tag < <(python3 "$ROOT/scripts/resolve-download.py" llama-vulkan "$tmp/releases.json")
        [[ -n $url && $sha =~ ^[0-9a-f]{64}$ && $tag =~ ^b[0-9]+$ ]] || return 1
        curl -fsSL --retry 3 "$url" -o "$tmp/$name"
        printf '%s  %s\n' "$sha" "$tmp/$name" | sha256sum -c -
        tar -tzf "$tmp/$name" | grep -Fx "llama-$tag/llama-cli" >/dev/null
        tar -xzf "$tmp/$name" -C "$tmp"
        root="$HOME/.local/share/llama.cpp"
        mkdir -p "$root" "$HOME/.local/bin"
        [[ ! -e $root/llama-$tag ]] || return 1
        mv "$tmp/llama-$tag" "$root/llama-$tag"
        ln -sfn "llama-$tag" "$root/current"
        printf '#!/usr/bin/env bash\nbase="%s/current"\nLD_LIBRARY_PATH="$base${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" exec "$base/llama-cli" "$@"\n' "$root" > "$HOME/.local/bin/llama-cli"
        chmod 755 "$HOME/.local/bin/llama-cli"
        "$HOME/.local/bin/llama-cli" --version
      );;
    ollama-release)
      (
        set -Eeuo pipefail
        local tmp url sha
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fsSL --retry 3 https://api.github.com/repos/ollama/ollama/releases/latest -o "$tmp/release.json"
        IFS=$'\t' read -r url sha < <(python3 "$ROOT/scripts/resolve-download.py" github "$tmp/release.json" ollama-linux-amd64.tar.zst ollama/ollama)
        [[ -n $url && $sha =~ ^[0-9a-f]{64}$ ]] || return 1
        curl -fsSL --retry 3 "$url" -o "$tmp/ollama-linux-amd64.tar.zst"
        printf '%s  %s\n' "$sha" "$tmp/ollama-linux-amd64.tar.zst" | sha256sum -c -
        tar --zstd -tf "$tmp/ollama-linux-amd64.tar.zst" | grep -Ex '(./)?bin/ollama' >/dev/null
        sudo tar --zstd -xf "$tmp/ollama-linux-amd64.tar.zst" -C /usr
        if ! getent passwd ollama >/dev/null; then sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama; fi
        getent group render >/dev/null && sudo usermod -aG render ollama || true
        getent group video >/dev/null && sudo usermod -aG video ollama || true
        cat > "$tmp/ollama.service" <<'EOF'
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        if [[ ! -e /etc/systemd/system/ollama.service ]]; then sudo install -m 644 "$tmp/ollama.service" /etc/systemd/system/ollama.service; fi
        sudo systemctl daemon-reload
        sudo systemctl enable --now ollama
        /usr/bin/ollama --version
      );;
    gpu-check)
      vulkaninfo --summary
      local llama_bin
      llama_bin=$(command -v llama-cli || printf '%s' "$HOME/.local/bin/llama-cli")
      [[ -x $llama_bin ]] && "$llama_bin" --list-devices;;
    release-tar)
      local binary=${arg%%:*} remainder=${arg#*:} archive checksum
      archive=${remainder%:*}; checksum=${remainder##*:}
      [[ $binary == zellij || $binary == starship || $binary == lazygit ]] || return 1
      [[ -f $archive && $checksum =~ ^[[:xdigit:]]{64}$ ]] || return 1
      printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c -
      tar -tzf "$archive" | grep -Ex "(./)?$binary" >/dev/null
      mkdir -p "$HOME/.local/bin"
      tar -xOzf "$archive" "$binary" > "$HOME/.local/bin/$binary"
      chmod 755 "$HOME/.local/bin/$binary"
      "$HOME/.local/bin/$binary" --version;;
    github-release-tar)
      (
        set -Eeuo pipefail
        local repo tmp url sha name member
        case $arg in
          lazygit) repo=jesseduffield/lazygit;;
          zellij) repo=zellij-org/zellij;;
          starship) repo=starship/starship;;
          *) return 1;;
        esac
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fsSL --retry 3 "https://api.github.com/repos/$repo/releases/latest" -o "$tmp/release.json"
        IFS=$'\t' read -r url sha name < <(python3 "$ROOT/scripts/resolve-download.py" github-product "$tmp/release.json" "$arg")
        [[ -n $url && $sha =~ ^[0-9a-f]{64}$ && -n $name ]] || return 1
        curl -fsSL --retry 3 "$url" -o "$tmp/$name"
        printf '%s  %s\n' "$sha" "$tmp/$name" | sha256sum -c -
        member=$(tar -tzf "$tmp/$name" | grep -Ex "(./)?$arg")
        [[ -n $member ]] || return 1
        tar -xOzf "$tmp/$name" "$member" > "$tmp/$arg"
        mkdir -p "$HOME/.local/bin"
        install -m 755 "$tmp/$arg" "$HOME/.local/bin/$arg"
        "$HOME/.local/bin/$arg" --version
      );;
    kvm-setup)
      if ! has_kvm; then
        [[ $arg == kvm_amd || $arg == kvm_intel ]] || return 1
        sudo modprobe kvm
        sudo modprobe "$arg"
        has_kvm || { echo 'KVM modules loaded but /dev/kvm is still absent; inspect modprobe and kernel logs' >&2; return 1; }
      fi
      if ! kvm_access; then
        [[ $(stat -c %G /dev/kvm) == kvm ]] || { echo '/dev/kvm is not owned by the kvm group; inspect its udev rule' >&2; return 1; }
        getent group kvm >/dev/null || return 1
        if ! id -nG | tr ' ' '\n' | grep -qx kvm; then
          sudo usermod -aG kvm "$(id -un)"
          echo 'KVM group added; sign out and back in, then rerun the installer' >&2
          return 3
        fi
        echo 'Current user still cannot access /dev/kvm; inspect device permissions' >&2
        return 1
      fi;;
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
      local rc=$?
      if (( rc == 3 )); then
        ACTION_RESULT[i]=deferred; ((skipped+=1)); log_line "FOLLOW-UP ${ACTION_TITLE[i]}: sign out and back in, then rerun"
      else
        ACTION_RESULT[i]=failed; ((failed+=1)); log_line "FAIL ${ACTION_TITLE[i]} (see log)"
      fi
    fi
  done
  printf '\nSummary: %d completed, %d failed, %d skipped.\n' "$completed" "$failed" "$skipped"
  (( failed == 0 ))
}
