#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" APT_SOURCE_DIR="$TMP/sources"
mkdir -p "$HOME" "$APT_SOURCE_DIR"
source "$ROOT/lib/detection.sh"
source "$ROOT/lib/planning.sh"
source "$ROOT/lib/package-manager.sh"
fail() { echo "FAIL: $*" >&2; exit 1; }
# A duplicate source must be repaired even when the package is already installed.
printf key > "$TMP/warp.gpg"
cat > "$APT_SOURCE_DIR/warpdotdev.sources" <<EOT
Types: deb
URIs: https://releases.warp.dev/linux/deb
Suites: stable
Components: main
Architectures: amd64
Signed-By: $TMP/warp.gpg
EOT
printf installer > "$APT_SOURCE_DIR/linux-dev-setup-warp.list"
sudo() { "$@"; }
refresh_apt() { [[ ! -f $APT_SOURCE_DIR/linux-dev-setup-warp.list ]]; }
run_action warp-repo-repair '' || fail 'Warp duplicate repair failed'
[[ ! -e $APT_SOURCE_DIR/linux-dev-setup-warp.list ]] || fail 'duplicate retained'
compgen -G "$HOME/.local/state/linux-dev-setup/repo-backups/linux-dev-setup-warp.list.*" >/dev/null || fail 'missing backup'
run_action warp-repo-repair ''
printf installer > "$APT_SOURCE_DIR/linux-dev-setup-warp.list"
sed -i 's/Types: deb/Types: deb-src/' "$APT_SOURCE_DIR/warpdotdev.sources"
if run_action warp-repo-repair ''; then fail 'invalid vendor accepted'; fi
[[ -f $APT_SOURCE_DIR/linux-dev-setup-warp.list ]] || fail 'invalid vendor removed fallback'
rm "$APT_SOURCE_DIR/warpdotdev.sources"
run_action warp-repo-repair ''
[[ -f $APT_SOURCE_DIR/linux-dev-setup-warp.list ]] || fail 'installer-only source removed'
echo 'ok - Warp repair validates, backs up, and is idempotent'
# Existing mise binaries must not suppress migration; no Node provisioning.
source "$ROOT/modules/ai-agents.sh"
DISTRO=ubuntu; DISTRO_VERSION=24.04
has_command() { [[ $1 == claude || $1 == codex || $1 == opencode || $1 == gemini ]]; }
package_installed() { return 1; }
repo_present() { return 1; }
plan_ai_agents
[[ " ${ACTION_TYPE[*]} " != *' mise-tool '* ]] || fail 'AI module provisions Node'
[[ " ${ACTION_TYPE[*]} " == *' ai-cli '* ]] || fail 'existing tools skip migration'
echo 'ok - AI module plans migration without Node installation'
# Fake only external vendor downloads/npm; exercise real migration and launchers.
source "$ROOT/lib/ai-cli.sh"
mkdir -p "$TMP/bin"
cat > "$TMP/bin/curl" <<'MOCK'
#!/usr/bin/env bash
binary=codex
for arg in "$@"; do case $arg in https://claude.ai/*) binary=claude;; https://opencode.ai/*) binary=opencode;; esac; done
while (( $# )); do case $1 in -o) dest=$2; shift;; esac; shift; done
cat > "$dest" <<'INSTALL'
#!/usr/bin/env bash
[ "${FAIL_INSTALL:-0}" != 1 ] || exit 1
if [ CLI_BINARY = codex ]; then
  [ "${CODEX_INSTALL_DIR:-}" = "$HOME/.local/bin" ] || exit 98
fi
target="$HOME/.local/bin/CLI_BINARY"
if [ CLI_BINARY = opencode ]; then target="$HOME/.opencode/bin/opencode"; fi
mkdir -p "$(dirname "$target")"
printf '#!/bin/sh\necho standalone\n' > "$target"
chmod 755 "$target"
INSTALL
sed -i "s/CLI_BINARY/$binary/g" "$dest"
MOCK
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:/usr/bin:/bin"
for version in 20 22; do
  prefix="$HOME/.local/share/mise/installs/node/$version"
  mkdir -p "$prefix/bin" "$prefix/lib/node_modules/@openai/codex" "$prefix/lib/node_modules/npm/bin" "$prefix/lib/node_modules/unrelated"
  touch "$prefix/lib/node_modules/npm/bin/npm-cli.js"
  cat > "$prefix/bin/node" <<'MOCK'
#!/usr/bin/env bash
[[ $2 == uninstall && $3 == --global && $4 == --prefix && $6 == @openai/codex ]] || exit 99
rm -rf "$5/lib/node_modules/@openai/codex"
MOCK
  chmod +x "$prefix/bin/node"
done
mkdir -p "$HOME/.codex"
printf credentials > "$HOME/.codex/auth.json"
if FAIL_INSTALL=1 install_ai_cli codex; then fail 'failed native installer accepted'; fi
[[ -d $HOME/.local/share/mise/installs/node/20/lib/node_modules/@openai/codex ]] || fail 'legacy deleted before replacement'
install_ai_cli codex
install_ai_cli codex
for version in 20 22; do
  [[ ! -d $HOME/.local/share/mise/installs/node/$version/lib/node_modules/@openai/codex ]] || fail 'legacy retained'
  [[ -d $HOME/.local/share/mise/installs/node/$version/lib/node_modules/unrelated ]] || fail 'unrelated package removed'
done
[[ $(cat "$HOME/.codex/auth.json") == credentials ]] || fail 'credentials modified'
install_ai_cli claude
install_ai_cli opencode
[[ $("$HOME/.local/bin/claude" --version) == standalone ]] || fail 'Claude native unavailable'
[[ $("$HOME/.local/bin/opencode" --version) == standalone ]] || fail 'OpenCode stable symlink unavailable'
echo 'ok - native migration verifies before cleanup across versions and preserves credentials'
cat > "$TMP/bin/npm" <<'MOCK'
#!/usr/bin/env bash
[[ $1 == install && $2 == --global && $3 == --prefix && $5 == @google/gemini-cli ]] || exit 99
mkdir -p "$4/bin"
printf '// gemini fixture\n' > "$4/bin/gemini"
MOCK
cat > "$TMP/bin/node" <<'MOCK'
#!/usr/bin/env bash
if [[ $1 == -e ]]; then [[ ${NODE_TEST_VERSION:-22} -ge 20 ]]; else printf 'node=%s args=%s\n' "${NODE_TEST_VERSION:-22}" "$*"; fi
MOCK
chmod +x "$TMP/bin/"{node,npm}
install_ai_cli gemini
for version in 20 22; do
  out=$(NODE_TEST_VERSION=$version "$HOME/.local/bin/gemini" --version)
  [[ $out == "node=$version "* ]] || fail 'Gemini ignores active Node'
done
if NODE_TEST_VERSION=18 "$HOME/.local/bin/gemini" --version; then fail 'unsupported Node accepted'; fi
printf 'export KEEP_ME=yes\n' > "$HOME/.bashrc"
configure_ai_path
configure_ai_path
[[ $(grep -c '^# linux-dev-setup AI PATH$' "$HOME/.bashrc") == 1 ]] || fail 'duplicate PATH block'
bash -n "$HOME/.bashrc"
if command -v zsh >/dev/null; then zsh -n "$HOME/.zshrc"; fi
out=$(bash -c 'source "$HOME/.bashrc"; PATH="/project/node/bin:$PATH"; _linux_dev_setup_ai_path; command -v gemini; echo "$KEEP_ME"')
[[ $out == "$HOME/.local/bin/gemini"$'\nyes' ]] || fail 'PATH precedence or configuration lost'
echo 'ok - Gemini uses active Node, validates version, and stable shell PATH is repeatable'
# Simulate a postinst creating a vendor source, followed by another package.
sed -i 's/Types: deb-src/Types: deb/' "$APT_SOURCE_DIR/warpdotdev.sources" 2>/dev/null || true
sudo() {
  if [[ $1 == apt-get && $2 == install ]]; then
    if [[ $5 == warp-terminal ]]; then
      cat > "$APT_SOURCE_DIR/warpdotdev.sources" <<EOT
Types: deb
URIs: https://releases.warp.dev/linux/deb
Suites: stable
Components: main
Signed-By: $TMP/warp.gpg
EOT
    else [[ ! -f $APT_SOURCE_DIR/linux-dev-setup-warp.list ]] || return 1; fi
  else "$@"; fi
}
refresh_apt() { :; }
run_action apt warp-terminal
run_action apt subsequent-package
[[ ! -f $APT_SOURCE_DIR/linux-dev-setup-warp.list ]] || fail 'postinst duplicate retained'
echo 'ok - Warp postinst cleanup precedes subsequent APT installs'

# The plan must expose duplicate repair without changing sources, shell files, or credentials.
source_snapshot=$(sha256sum "$APT_SOURCE_DIR/warpdotdev.sources")
printf installer > "$APT_SOURCE_DIR/linux-dev-setup-warp.list"
cat > "$TMP/os-release" <<'OS'
ID=ubuntu
VERSION_ID=24.04
VERSION_CODENAME=noble
ID_LIKE=debian
OS
shell_snapshot=$(sha256sum "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.codex/auth.json")
out=$(DS_TEST_MODE=1 DS_TEST_OS_RELEASE="$TMP/os-release" DS_TEST_ARCH=x86_64 bash "$ROOT/install.sh" --module ai-agents --dry-run)
[[ $out == *'Warp repository repair'* && $out != *'Node.js LTS via mise'* ]] || fail 'repair missing from dry-run or Node provisioning planned'
[[ $(sha256sum "$APT_SOURCE_DIR/warpdotdev.sources") == "$source_snapshot" ]] || fail 'dry-run changed vendor source'
[[ -f $APT_SOURCE_DIR/linux-dev-setup-warp.list ]] || fail 'dry-run removed duplicate'
[[ $(sha256sum "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.codex/auth.json") == "$shell_snapshot" ]] || fail 'dry-run changed user files'
rm -f "$HOME/.local/bin/gemini"
if NODE_TEST_VERSION=18 install_ai_cli gemini; then fail 'Gemini installed on incompatible Node'; fi
[[ ! -e $HOME/.local/bin/gemini ]] || fail 'unsupported runtime published a launcher'
echo 'ok - dry-run preserves setup; incompatible Node installs no runtime or launcher'
command() {
  if [[ $1 == -v && ( $2 == node || $2 == npm ) ]]; then return 1; fi
  builtin command "$@"
}
if install_ai_cli gemini; then fail 'Gemini installed without active Node/npm'; fi
unset -f command
[[ ! -e $HOME/.local/bin/gemini ]] || fail 'missing runtime published a launcher'
# Resolve custom mise locations before deciding an existing symlink is native.
export MISE_DATA_DIR="$TMP/custom-mise"
mkdir -p "$MISE_DATA_DIR/installs/node/22/bin"
printf '#!/bin/sh\necho old\n' > "$MISE_DATA_DIR/installs/node/22/bin/claude"
chmod +x "$MISE_DATA_DIR/installs/node/22/bin/claude"
ln -sfn "$MISE_DATA_DIR/installs/node/22/bin/claude" "$HOME/.local/bin/claude"
if ai_cli_ready claude; then fail 'custom mise symlink treated as native'; fi
echo 'ok - missing runtime is reported; custom mise paths still migrate'
printf 'deb [signed-by=/missing] https://downloads.claude.ai/claude-desktop/apt/stable stable main\n' > "$APT_SOURCE_DIR/claude-desktop.list"
printf installer > "$APT_SOURCE_DIR/linux-dev-setup-claude-desktop.list"
if repair_claude_repo; then fail 'invalid Claude vendor accepted'; fi
[[ -f $APT_SOURCE_DIR/linux-dev-setup-claude-desktop.list ]] || fail 'Claude fallback removed without valid vendor source'
printf 'deb [arch=amd64 signed-by=%s] https://downloads.claude.ai/claude-desktop/apt/stable stable main\n' "$TMP/warp.gpg" > "$APT_SOURCE_DIR/claude-desktop.list"
repair_claude_repo
[[ ! -f $APT_SOURCE_DIR/linux-dev-setup-claude-desktop.list ]] || fail 'Claude duplicate retained'
echo 'ok - Claude cleanup validates vendor source and preserves fallback when invalid'
