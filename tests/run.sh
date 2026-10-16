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
check interactive-optional-disabled 'Disabled in settings' "$out"
if printf '99\n' | bash "$ROOT/install.sh" --interactive --dry-run >"$TMP/out" 2>&1; then fail 'invalid interactive choice accepted'; fi
check interactive-invalid 'Invalid selection' "$(cat "$TMP/out")"
out=$(bash "$ROOT/install.sh" --module ai-agents --dry-run)
check claude-desktop-repository 'claude-desktop repository' "$out"
check chatgpt-desktop 'ChatGPT Desktop' "$out"
out=$(bash "$ROOT/diagnose.sh")
check diagnostics 'GPU' "$out"
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
  execute_plan || true
  printf "results=%s,%s" "${ACTION_RESULT[0]}" "${ACTION_RESULT[1]}"
')
check dependent-skip 'results=failed,skipped' "$out"
export DS_TEST_OS_RELEASE="$TMP/mint"
out=$(bash "$ROOT/install.sh" --module docker --dry-run)
check derivative 'Manual intervention' "$out"
[[ $out != *'Suites: wilma'* ]] || fail 'derivative used wrong suite'
out=$(bash "$ROOT/install.sh" --module ai-agents --dry-run)
check mint-chatgpt-base 'ChatGPT Desktop' "$out"
[[ $out != *'does not list this distribution/version'* ]] || fail 'Mint was not mapped to Ubuntu base compatibility'
out=$(ROOT="$ROOT" TMP="$TMP" bash -c '
  source "$ROOT/lib/package-manager.sh"
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
printf 'All tests passed\n'
