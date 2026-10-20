#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" ROOT
mkdir -p "$HOME"
source "$ROOT/lib/planning.sh"
source "$ROOT/lib/package-manager.sh"
source "$ROOT/modules/editors.sh"
plan_apt() { :; }
has_command() { return 1; }
package_installed() { return 1; }
plan_editors
[[ ${ACTION_TYPE[*]} == vscode-deb ]]
[[ ${ACTION_TITLE[*]} != *Antigravity* ]]
# Run the package action; mock only external downloads/APT, keeping verification real.
curl() { local dst; while (( $# )); do case $1 in -o) dst=$2; shift 2;; *) shift;; esac; done; printf package > "$dst"; }
dpkg-deb() { case ${*: -1} in Package) echo "${FIXTURE_PACKAGE:-code}";; Architecture) echo amd64;; esac; }
sudo() {
  case $1 in
    debconf-set-selections) cat >> "$TMP/operations";;
    apt-get) printf '%s\n' "$*" >> "$TMP/operations";;
    *) return 1;;
  esac
}
refresh_apt() { echo refresh >> "$TMP/operations"; }
has_command() { [[ $1 == code ]]; }
run_action vscode-deb ''
grep -Fq 'code code/add-microsoft-repo boolean true' "$TMP/operations"
grep -Fq 'apt-get install --no-remove -y' "$TMP/operations"
[[ $(sed -n '1p' "$TMP/operations") == 'code code/add-microsoft-repo boolean true' ]]
rm "$TMP/operations"
FIXTURE_PACKAGE=wrong
if run_action vscode-deb ''; then echo 'FAIL: wrong package accepted'; exit 1; fi
[[ ! -e $TMP/operations ]]
# Ordered checklist: manual account step gates extension installation and sign-in.
source "$ROOT/lib/checklist.sh"
has_command() { [[ $1 == code || $1 == agy ]]; }
package_installed() { return 1; }
flatpak_installed() { return 1; }
checklist_catalog
[[ ${CHECKLIST_IDS[*]} == 'agy vscode-account vscode-extension' ]]
[[ $(checklist_status vscode-extension 1) == blocked ]]
if checklist_launch vscode-extension cli; then echo 'FAIL: extension install before account review'; exit 1; fi
[[ ! -e $TMP/code-args ]]
checklist_mark vscode-account
code() {
  printf '%s\n' "$*" >> "$TMP/code-args"
  case $1 in
    --list-extensions) [[ ! -e $TMP/extension-installed ]] || echo google.google-antigravity;;
    --install-extension) touch "$TMP/extension-installed";;
  esac
}
# Exercise the terminal installer with a PATH fixture.
mkdir "$TMP/bin"
cat > "$TMP/bin/code" <<'CODE'
#!/usr/bin/env bash
case $1 in
 --list-extensions) [[ ! -e $HOME/extension-installed ]] || echo google.google-antigravity;;
 --install-extension)
   [[ $2 == google.google-antigravity ]] || exit 1
   [[ ${CODE_TEST_FAIL:-0} != 1 ]] || exit 1
   echo installed >> "$HOME/install-invocations"
   touch "$HOME/extension-installed"; echo installed;;
esac
CODE
chmod 755 "$TMP/bin/code"
# Selecting the terminal step directly must also enforce account review.
mv "$(checklist_state_file)" "$TMP/account-state"
if PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/checklist-terminal.sh" vscode-extension </dev/null; then
  echo 'FAIL: direct terminal step bypassed account review'; exit 1
fi
[[ ! -e $HOME/extension-installed ]]
mv "$TMP/account-state" "$(checklist_state_file)"
if CODE_TEST_FAIL=1 PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/checklist-terminal.sh" vscode-extension </dev/null; then
  echo 'FAIL: extension installation failure ignored'; exit 1
fi
[[ ! -e $HOME/extension-installed ]]
PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/checklist-terminal.sh" vscode-extension </dev/null
[[ -f $HOME/extension-installed ]]
PATH="$TMP/bin:$PATH" bash "$ROOT/scripts/checklist-terminal.sh" vscode-extension </dev/null
[[ $(wc -l < "$HOME/install-invocations") == 1 ]]
# The extension's exact ID must be detected; unrelated extensions do not satisfy the probe.
code() { echo unrelated.extension; }
if checklist_probed vscode-extension; then echo 'FAIL: unrelated extension accepted'; exit 1; fi
code() { echo google.google-antigravity; }
checklist_probed vscode-extension
echo 'Editor and VS Code checklist tests passed'
