#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/home" "$TMP/bin"
cat > "$TMP/ubuntu" <<'EOF'
ID=ubuntu
VERSION_ID=24.04
VERSION_CODENAME=noble
ID_LIKE=debian
EOF
cat > "$TMP/mint" <<'EOF'
ID=linuxmint
VERSION_ID=22
VERSION_CODENAME=wilma
UBUNTU_CODENAME=noble
ID_LIKE="ubuntu debian"
EOF
cat > "$TMP/fedora" <<'EOF'
ID=fedora
VERSION_ID=42
ID_LIKE="rhel fedora"
EOF
export DS_TEST_MODE=1 DS_TEST_ARCH=x86_64 HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config"
unset ANDROID_HOME ANDROID_SDK_ROOT
export DS_TEST_FORCE_MISSING=lazygit,zellij,starship,zsh,zsh-autosuggestions,zsh-syntax-highlighting,docker,docker-desktop,docker-ce,docker.io,containerd,runc,podman-docker,agy,code,claude-desktop,chatgpt,ollama,llama-cli,vivaldi,vivaldi-stable,google-chrome,google-chrome-stable,tailscale
export DS_TEST_IGNORE_REPOS=1
if [[ -e /etc/apt/sources.list.d/claude-desktop.list && -e /etc/apt/sources.list.d/linux-dev-setup-claude-desktop.list ]]; then
  mkdir -p "$TMP/apt-sources"
  cp -a /etc/apt/sources.list.d/. "$TMP/apt-sources/"
  rm -f "$TMP/apt-sources/linux-dev-setup-claude-desktop.list"
  export APT_SOURCE_PARTS_OVERRIDE="$TMP/apt-sources"
fi
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
check() { local label=$1 expected=$2 output=$3; [[ $output == *"$expected"* ]] || fail "$label: expected $expected"; printf 'ok - %s\n' "$label"; }
out=$(bash "$ROOT/install.sh" --help)
check help '--dry-run' "$out"
out=$(bash "$ROOT/install.sh" --list)
check list 'ai-agents' "$out"
if bash "$ROOT/install.sh" --module bogus --dry-run >"$TMP/out" 2>&1; then fail 'invalid module accepted'; fi
check invalid-module 'Unknown module' "$(cat "$TMP/out")"
export DS_TEST_OS_RELEASE="$TMP/ubuntu"
out=$(bash "$ROOT/install.sh" --module javascript --dry-run)
check js-plan 'Node.js LTS via mise' "$out"
[[ $out != *'Docker Engine'* ]] || fail 'module isolation'
check dry-run-summary 'Will install' "$out"
out=$(printf '3\n' | bash "$ROOT/install.sh" --interactive --dry-run)
check interactive-selection 'Selected modules: javascript' "$out"
[[ $out != *'Docker contexts'* ]] || fail 'interactive selection included Docker'
out=$(printf '4\nn\n' | bash "$ROOT/install.sh" --interactive --dry-run)
check interactive-optional 'Docker Desktop' "$out"
[[ $out == *'Disabled in settings'* || $out == *'Existing installation retained'* ]] || fail 'interactive Docker optional choice missing'
printf 'ok - interactive-optional-disabled\n'
if printf '99\n' | bash "$ROOT/install.sh" --interactive --dry-run >"$TMP/out" 2>&1; then fail 'invalid interactive choice accepted'; fi
check interactive-invalid 'Invalid selection' "$(cat "$TMP/out")"
out=$(bash "$ROOT/install.sh" --module ai-agents --dry-run)
check claude-desktop-repository 'claude-desktop repository' "$out"
check chatgpt-desktop 'ChatGPT Desktop' "$out"
out=$(bash "$ROOT/diagnose.sh")
check diagnostics 'GPU' "$out"
[[ $out == *'CPU flag:'* || $out == *'CPU virtualization flag'* ]] || fail 'KVM CPU diagnostic missing'
out=$(bash "$ROOT/install.sh" --all --dry-run)
check all-plan 'Docker contexts' "$out"
check all-operations 'operation:' "$out"
[[ ! -e "$HOME/.local/state/linux-dev-setup" ]] || fail 'dry run wrote log'
[[ ! -e "$HOME/.zshrc" ]] || fail 'dry run wrote dotfile'
if bash "$ROOT/install.sh" --module javascript --yes >"$TMP/out" 2>&1; then fail 'test fixture execution accepted'; fi
check fixture-guard 'Test fixture mode cannot execute changes' "$(cat "$TMP/out")"
out=$(ROOT="$ROOT" TMP="$TMP" bash -c '
  set -Eeuo pipefail
  source "$ROOT/lib/planning.sh"
  source "$ROOT/lib/logging.sh"
  source "$ROOT/lib/package-manager.sh"
  LOG_FILE="$TMP/exec.log"; : > "$LOG_FILE"
  run_action() { [[ $1 != repo-tools ]]; }
  add_action install prerequisite repo-tools "" - ""
  add_action install dependent apt example 0 ""
  confirm_planned_changes() { :; }
  execute_plan || true
  printf "results=%s,%s" "${ACTION_RESULT[0]}" "${ACTION_RESULT[1]}"
')
check dependent-skip 'results=failed,skipped' "$out"
out=$(ROOT="$ROOT" bash -c '
  source "$ROOT/lib/package-manager.sh"
  sudo() { printf "sudo:%s\n" "$*"; [[ $* != "apt-get update" ]]; }
  run_action apt example && echo unexpected || echo apt-update-failed
')
check apt-failure-propagates 'apt-update-failed' "$out"
[[ $out != *'apt-get install'* ]] || fail 'APT install ran after update failed'
export DS_TEST_OS_RELEASE="$TMP/mint"
out=$(DS_TEST_KVM=missing DS_TEST_CPU_VIRT=none bash "$ROOT/install.sh" --module docker --dry-run)
check derivative 'Manual intervention' "$out"
[[ $out != *'Suites: wilma'* ]] || fail 'derivative used wrong suite'
check desktop-kvm 'Docker Desktop requires KVM' "$out"
check kvm-firmware-followup 'Enable SVM/AMD-V or VT-x' "$out"
[[ $out != *'Will install:'*'docker-ce'* ]] || fail 'Engine planned by default'
check engine-followup 'Explicit Engine fallback' "$out"
out=$(DS_TEST_KVM=missing DS_TEST_CPU_VIRT=svm bash "$ROOT/install.sh" --module docker --dry-run)
check kvm-setup-plan 'Load KVM modules' "$out"
check kvm-setup-operation 'modprobe kvm' "$out"
[[ $out != *'Docker Desktop requires KVM'* ]] || fail 'KVM-capable host treated as unsupported'
out=$(DS_TEST_KVM=missing DS_TEST_CPU_VIRT=none bash "$ROOT/install.sh" --module docker --dry-run)
check kvm-no-cpu 'Docker Desktop requires KVM' "$out"
[[ $out != *'modprobe kvm'* ]] || fail 'KVM module planned without CPU flag'
out=$(ROOT="$ROOT" bash -c '
  source "$ROOT/lib/package-manager.sh"
  has_kvm() { [[ ${MOCK_KVM_LOADED:-0} == 1 ]]; }
  kvm_access() { return 0; }
  sudo() { printf "%s\n" "$*"; [[ $* != "modprobe kvm_amd" ]] || MOCK_KVM_LOADED=1; }
  run_action kvm-setup kvm_amd
')
check kvm-load-base 'modprobe kvm' "$out"
check kvm-load-amd 'modprobe kvm_amd' "$out"
cat > "$TMP/docker-notes.html" <<'EOF'
<a href="https://desktop.docker.com/linux/main/amd64/123/docker-desktop-amd64.deb?campaign=test">Debian</a>
EOF
cat > "$TMP/docker-sums.txt" <<'EOF'
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa *docker-desktop-amd64.deb
EOF
out=$(python3 "$ROOT/scripts/resolve-download.py" docker-url "$TMP/docker-notes.html")
[[ $out == 'https://desktop.docker.com/linux/main/amd64/123/docker-desktop-amd64.deb' ]] || fail 'Docker release URL not resolved'
out=$(python3 "$ROOT/scripts/resolve-download.py" docker-checksum "$TMP/docker-sums.txt")
[[ $out == aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ]] || fail 'Docker checksum not resolved'
printf 'fixture-deb' > "$TMP/mock-docker.deb"
mock_sha=$(sha256sum "$TMP/mock-docker.deb" | cut -d' ' -f1)
printf '%s *docker-desktop-amd64.deb\n' "$mock_sha" > "$TMP/mock-docker-sums.txt"
out=$(ROOT="$ROOT" MOCK_ROOT="$TMP" bash -c '
  source "$ROOT/lib/package-manager.sh"
  has_kvm() { return 0; }; kvm_access() { return 0; }
  package_installed() { return 0; }; refresh_apt() { :; }
  docker() { :; }; sudo() { printf "sudo:%s\n" "$*"; }
  curl() {
    local url="" dst=""
    while (( $# )); do case $1 in -o) dst=$2; shift 2;; -*) shift;; *) url=$1; shift;; esac; done
    case $url in
      *release-notes*) cp "$MOCK_ROOT/docker-notes.html" "$dst";;
      *checksums.txt) cp "$MOCK_ROOT/mock-docker-sums.txt" "$dst";;
      *docker-desktop-amd64.deb) cp "$MOCK_ROOT/mock-docker.deb" "$dst";;
      *) return 1;;
    esac
  }
  run_action docker-desktop auto
')
check docker-verified-before-apt 'sudo:apt-get install --no-remove -y' "$out"
printf '%064d *docker-desktop-amd64.deb\n' 0 > "$TMP/mock-docker-sums.txt"
out=$(ROOT="$ROOT" MOCK_ROOT="$TMP" bash -c '
  source "$ROOT/lib/package-manager.sh"
  has_kvm() { return 0; }; kvm_access() { return 0; }
  package_installed() { return 0; }; refresh_apt() { :; }
  docker() { :; }; sudo() { printf "sudo:%s\n" "$*"; }
  curl() {
    local url="" dst=""
    while (( $# )); do case $1 in -o) dst=$2; shift 2;; -*) shift;; *) url=$1; shift;; esac; done
    case $url in
      *release-notes*) cp "$MOCK_ROOT/docker-notes.html" "$dst";;
      *checksums.txt) cp "$MOCK_ROOT/mock-docker-sums.txt" "$dst";;
      *docker-desktop-amd64.deb) cp "$MOCK_ROOT/mock-docker.deb" "$dst";;
      *) return 1;;
    esac
  }
  run_action docker-desktop auto
' 2>&1 || true)
[[ $out != *'sudo:apt-get install'* ]] || fail 'Docker installed after checksum mismatch'
cat > "$TMP/android.html" <<'EOF'
<tr><td>Linux<br>(64-bit)</td><td><button data-modal-dialog-id="studio_linux_bundle_download">android-studio-test-linux.tar.gz</button></td><td>1 GB</td><td>cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc</td></tr>
<a href="https://edgedl.me.gvt1.com/android/studio/ide-zips/1/android-studio-test-linux.tar.gz" id="agree-button__studio_linux_bundle_download">Download</a>
EOF
out=$(python3 "$ROOT/scripts/resolve-download.py" android "$TMP/android.html")
check android-resolve 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc' "$out"
python3 - "$TMP/unsafe.tar.gz" <<'PY'
import io, sys, tarfile
with tarfile.open(sys.argv[1], 'w:gz') as archive:
    item = tarfile.TarInfo('../outside')
    item.size = 1
    archive.addfile(item, io.BytesIO(b'x'))
PY
if python3 "$ROOT/scripts/resolve-download.py" tar-root "$TMP/unsafe.tar.gz" 'fixture-root' >"$TMP/out" 2>&1; then fail 'unsafe tar path accepted'; fi
cat > "$TMP/chatgpt.html" <<'EOF'
<a href="https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb">Download .deb for x64</a>
EOF
out=$(python3 "$ROOT/scripts/resolve-download.py" chatgpt "$TMP/chatgpt.html")
check chatgpt-resolve 'chatgpt_amd64.deb' "$out"
cat > "$TMP/slack-instructions.html" <<'EOF'
<iframe src="https://downloads.slack-edge.com/desktop-releases/linux/x64/4.52.178/slack-desktop-4.52.178-amd64.deb"></iframe>
<a href="https://downloads.slack-edge.com/desktop-releases/linux/x64/4.52.178/slack-desktop-4.52.178-amd64.deb">Try again</a>
EOF
out=$(python3 "$ROOT/scripts/resolve-download.py" slack-deb "$TMP/slack-instructions.html")
check slack-resolve 'slack-desktop-4.52.178-amd64.deb' "$out"
cat > "$TMP/agy.json" <<'EOF'
{"version":"1.0.0","url":"https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/agy.tar.gz","sha512":"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"}
EOF
out=$(python3 "$ROOT/scripts/resolve-download.py" antigravity-cli "$TMP/agy.json")
check agy-manifest 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd' "$out"
cat > "$TMP/github-release.json" <<'EOF'
{"assets":[{"name":"starship-x86_64-unknown-linux-musl.tar.gz","browser_download_url":"https://github.com/starship/starship/releases/download/v1/starship-x86_64-unknown-linux-musl.tar.gz","digest":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}]}
EOF
out=$(python3 "$ROOT/scripts/resolve-download.py" github "$TMP/github-release.json" 'starship-x86_64-unknown-linux-musl.tar.gz' 'starship/starship')
check github-digest 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' "$out"
# These checks exercise release fallbacks even on hosts with newer APT catalogs.
apt-cache() {
  case ${*: -1} in
    starship|zellij|lazygit) printf '  Candidate: (none)\n';;
    *) command apt-cache "$@";;
  esac
}
export -f apt-cache
out=$(DS_TEST_OS_RELEASE="$TMP/mint" bash "$ROOT/install.sh" --module terminal --dry-run)
check starship-auto 'download verified Starship release' "$out"
check zellij-auto 'download verified Zellij release' "$out"
out=$(DS_TEST_OS_RELEASE="$TMP/mint" bash "$ROOT/install.sh" --module system --dry-run)
check lazygit-auto 'download verified Lazygit release' "$out"
unset -f apt-cache
out=$(DS_TEST_OS_RELEASE="$TMP/mint" bash "$ROOT/install.sh" --module applications --dry-run)
check tailscale-auto 'tailscale repository' "$out"
check chrome-auto 'google-chrome repository' "$out"
check vivaldi-auto 'vivaldi repository' "$out"
out=$(DS_TEST_OS_RELEASE="$TMP/mint" bash "$ROOT/install.sh" --module editors,ai-agents --dry-run)
check vscode-auto 'Visual Studio Code' "$out"
check antigravity-cli-auto 'download verified Antigravity CLI' "$out"
out=$(DS_TEST_OS_RELEASE="$TMP/mint" bash "$ROOT/install.sh" --module local-llms --dry-run)
check llama-auto 'download verified llama.cpp Vulkan release' "$out"
check ollama-auto 'download verified Ollama release' "$out"
check gpu-check-auto 'GPU backend check' "$out"
out=$(DS_TEST_KVM=present DS_TEST_CPU_VIRT=svm bash "$ROOT/install.sh" --module docker --dry-run)
check docker-auto 'Docker Desktop' "$out"
check docker-download 'download official .deb and checksum' "$out"
[[ $out != *'Set DOCKER_DESKTOP_DEB'* ]] || fail 'Docker Desktop still requires local artifact'
out=$(DS_TEST_KVM=missing DS_TEST_CPU_VIRT=svm bash "$ROOT/install.sh" --module android --dry-run)
check android-kvm-setup 'Load KVM modules for Android emulator' "$out"
out=$(ROOT="$ROOT" bash -c '
  source "$ROOT/lib/package-manager.sh"
  has_kvm() { return 0; }
  kvm_access() { return 1; }
  stat() { printf kvm; }
  getent() { return 0; }
  id() { [[ $1 == -un ]] && printf fixture || printf users; }
  sudo() { printf "%s\n" "$*"; }
  run_action kvm-setup kvm_amd
  printf "result=%s\n" "$?"
' 2>&1)
check kvm-group 'usermod -aG kvm fixture' "$out"
check kvm-login 'result=3' "$out"
out=$(DS_TEST_KVM=missing DS_TEST_CPU_VIRT=none INSTALL_DOCKER_ENGINE_FALLBACK=1 bash "$ROOT/install.sh" --module docker --dry-run)
check engine-opt-in 'docker-ce' "$out"
out=$(bash "$ROOT/install.sh" --module android --dry-run)
[[ $out != *'sudo apt-get install -y adb'* ]] || fail 'duplicate ADB planned'
check sdk-commandline-pending 'Android Command-line Tools' "$out"
check sdk-packages-pending 'Android SDK packages' "$out"
check android-auto 'download verified Android Studio tarball' "$out"
mkdir -p "$HOME/custom-sdk/platform-tools" "$HOME/custom-sdk/cmdline-tools/latest/bin"
touch "$HOME/custom-sdk/platform-tools/adb" "$HOME/custom-sdk/cmdline-tools/latest/bin/sdkmanager"
chmod +x "$HOME/custom-sdk/platform-tools/adb" "$HOME/custom-sdk/cmdline-tools/latest/bin/sdkmanager"
out=$(ANDROID_SDK_ROOT="$HOME/custom-sdk" bash "$ROOT/install.sh" --module android --dry-run)
check sdk-detection 'Existing SDK manager retained' "$out"
[[ $out != *'Will install:'*'Android Command-line Tools'* ]] || fail 'command-line tools incorrectly pending with valid SDK'
cat > "$HOME/.zshrc" <<'EOF'
# user configuration
# linux-dev-setup managed block
old content
# end linux-dev-setup
EOF
out=$(bash "$ROOT/install.sh" --module terminal --dry-run)
check zsh-migration 'Will configure:' "$out"
check zsh-shell 'Default shell' "$out"
check autosuggestions-package 'zsh-autosuggestions' "$out"
check syntax-highlighting-package 'zsh-syntax-highlighting' "$out"
out=$(ROOT="$ROOT" bash -c '
  source "$ROOT/lib/planning.sh"
  source "$ROOT/lib/detection.sh"
  source "$ROOT/modules/terminal.sh"
  package_candidate() { return 1; }
  package_installed() { return 1; }
  has_command() { return 1; }
  DISTRO=linuxmint; BASE_CODENAME=noble
  plan_terminal
  for i in "${!ACTION_TITLE[@]}"; do
    case ${ACTION_TITLE[i]} in Zsh|"Zsh autosuggestions"|"Zsh syntax highlighting") printf "%s:%s\n" "${ACTION_TITLE[i]}" "${ACTION_TYPE[i]}";; esac
  done
')
check zsh-known-apt 'Zsh:apt' "$out"
check autosuggestions-known-apt 'Zsh autosuggestions:apt' "$out"
check syntax-highlighting-known-apt 'Zsh syntax highlighting:apt' "$out"
out=$(ROOT="$ROOT" HOME="$HOME" bash -c 'source "$ROOT/lib/package-manager.sh"; zsh() { :; }; zsh_plugins_ready() { :; }; run_action shell-zsh ""; cat "$HOME/.zshrc"')
check zsh-preserve 'user configuration' "$out"
[[ $out != *'old content'* ]] || fail 'old managed block retained'
[[ $(grep -c '^# linux-dev-setup managed block$' "$HOME/.zshrc") == 1 ]] || fail 'duplicate Zsh managed block'
[[ $(tail -2 "$HOME/.zshrc" | head -1) == *'zsh-syntax-highlighting.zsh'* ]] || fail 'syntax highlighting not last'
[[ $(grep -c 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' "$HOME/.zshrc") == 1 ]] || fail 'autosuggestions not sourced exactly once'
[[ $(grep -c 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' "$HOME/.zshrc") == 1 ]] || fail 'syntax highlighting not sourced exactly once'
out=$(ROOT="$ROOT" HOME="$HOME" bash -c 'source "$ROOT/lib/package-manager.sh"; zsh() { :; }; zsh_plugins_ready() { :; }; run_action shell-zsh ""; grep -c "^# linux-dev-setup managed block$" "$HOME/.zshrc"')
[[ $out == 1 ]] || fail 'Zsh rerun duplicated block'
out=$(ROOT="$ROOT" HOME="$HOME" bash -c 'source "$ROOT/lib/package-manager.sh"; zsh_plugins_ready() { return 1; }; run_action shell-zsh "" && echo unexpected || echo plugin-check-failed')
check zsh-plugin-check 'plugin-check-failed' "$out"
out=$(bash "$ROOT/install.sh" --module ai-agents --dry-run)
check mint-chatgpt-base 'ChatGPT Desktop' "$out"
[[ $out != *'does not list this distribution/version'* ]] || fail 'Mint was not mapped to Ubuntu base compatibility'
check chatgpt-auto 'download official ChatGPT .deb' "$out"
out=$(ROOT="$ROOT" TMP="$TMP" bash -c '
  source "$ROOT/lib/package-manager.sh"
  source "$ROOT/lib/detection.sh"
  repo_present() { [[ $1 == warp ]]; }
  sudo() { printf "unexpected sudo\\n"; return 99; }
  curl() { printf "unexpected curl\\n"; return 99; }
  setup_repo warp
')
[[ -z $out ]] || fail 'Warp duplicated an existing upstream repository'
printf 'ok - warp-existing-source\n'
export DS_TEST_OS_RELEASE="$TMP/fedora"
if bash "$ROOT/install.sh" --dry-run >"$TMP/out" 2>&1; then fail 'unsupported distribution accepted'; fi
check unsupported 'Unsupported distribution' "$(cat "$TMP/out")"
bash "$ROOT/scripts/package.sh" --output "$TMP/dist" --repo example/linux-dev-setup
version=$(<"$ROOT/VERSION")
archive="$TMP/dist/linux-dev-setup-v$version.tar.gz"
[[ -f $archive ]] || fail 'release archive missing'
[[ -f "$archive.sha256" ]] || fail 'release checksum missing'
[[ -f "$TMP/dist/install.sh" ]] || fail 'remote installer missing'
check bootstrap-repo 'example/linux-dev-setup' "$(cat "$TMP/dist/install.sh")"
check bootstrap-default 'set -- --interactive' "$(cat "$TMP/dist/install.sh")"
out=$(tar -tzf "$archive")
check package-installer "linux-dev-setup-v$version/install.sh" "$out"
check package-modules "linux-dev-setup-v$version/modules/javascript.sh" "$out"
check package-resolver "linux-dev-setup-v$version/scripts/resolve-download.py" "$out"
check package-checklist-terminal "linux-dev-setup-v$version/scripts/checklist-terminal.sh" "$out"
[[ $out != *'.git/'* ]] || fail 'archive contains git metadata'
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$TMP/dist" && sha256sum -c "$(basename "$archive").sha256") >/dev/null
else
  (cd "$TMP/dist" && shasum -a 256 -c "$(basename "$archive").sha256") >/dev/null
fi
printf 'ok - package checksum\n'
mkdir -p "$TMP/unpacked"
tar -xzf "$archive" -C "$TMP/unpacked"
out=$("$TMP/unpacked/linux-dev-setup-v$version/install.sh" --help)
check package-runs 'Usage: ./install.sh' "$out"
cat > "$TMP/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
destination=''
url=''
while (( $# )); do
  case $1 in
    --output) destination=$2; shift 2;;
    --retry) shift 2;;
    *) url=$1; shift;;
  esac
done
[[ $url == https://github.com/example/linux-dev-setup/releases/download/* ]]
cp "$MOCK_DIST/${url##*/}" "$destination"
if [[ ${MOCK_CORRUPT:-0} == 1 && $url == *.tar.gz ]]; then printf 'corrupt' >> "$destination"; fi
EOF
chmod +x "$TMP/bin/curl"
export MOCK_DIST="$TMP/dist"
export DS_TEST_OS_RELEASE="$TMP/ubuntu"
out=$(cat "$TMP/dist/install.sh" | PATH="$TMP/bin:$PATH" bash -s -- --module javascript --dry-run)
check bootstrap-executes 'Node.js LTS via mise' "$out"
if cat "$TMP/dist/install.sh" | PATH="$TMP/bin:$PATH" bash >"$TMP/out" 2>&1; then
  fail 'bootstrap started interactive mode without a terminal'
fi
check bootstrap-needs-tty 'Interactive installation requires a terminal' "$(cat "$TMP/out")"
if cat "$TMP/dist/install.sh" | PATH="$TMP/bin:$PATH" MOCK_CORRUPT=1 bash -s -- --module javascript --dry-run >"$TMP/out" 2>&1; then
  fail 'bootstrap accepted invalid checksum'
fi
check bootstrap-checksum 'FAILED' "$(cat "$TMP/out")"
bash "$ROOT/tests/confirmation.sh"
bash "$ROOT/tests/editors.sh"
bash "$ROOT/tests/cli-repair.sh"
bash "$ROOT/tests/desktop-setup.sh"
bash "$ROOT/tests/ui.sh"
printf 'All tests passed\n'
