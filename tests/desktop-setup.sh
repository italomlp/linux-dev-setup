#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
unset ANDROID_HOME ANDROID_SDK_ROOT
unset DS_TEST_MODE DS_TEST_FORCE_MISSING DS_TEST_IGNORE_REPOS DS_TEST_OS_RELEASE DS_TEST_ARCH
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }
check() { [[ $2 == *"$3"* ]] || fail "$1: expected $3"; echo "ok - $1"; }

mkdir -p "$TMP/apt" "$TMP/home"
cat > "$TMP/apt/google-chrome.sources" <<'EOF'
Types: deb
URIs: https://dl.google.com/linux/chrome-stable/deb/
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/google-chrome.gpg
EOF
cat > "$TMP/apt/vivaldi.sources" <<'EOF'
Types: deb
URIs: https://repo.vivaldi.com/stable/deb/
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/vivaldi.gpg
EOF
touch "$TMP/apt/linux-dev-setup-google-chrome.list" "$TMP/apt/linux-dev-setup-vivaldi.list"
touch "$TMP/vendor-key"
sed -i "s|/usr/share/keyrings/google-chrome.gpg|$TMP/vendor-key|" "$TMP/apt/google-chrome.sources"
sed -i "s|/usr/share/keyrings/vivaldi.gpg|$TMP/vendor-key|" "$TMP/apt/vivaldi.sources"
mkdir -p "$TMP/vendor-bin"
cat > "$TMP/vendor-bin/apt-cache" <<'EOF'
#!/usr/bin/env bash
case $* in
  *google-chrome-stable*) echo 'https://dl.google.com/linux/chrome-stable/deb stable/main amd64 Packages';;
  *vivaldi-stable*) echo 'https://repo.vivaldi.com/stable/deb stable/main amd64 Packages';;
esac
awk 'BEGIN {for (i=0; i<10000; i++) print "unrelated package metadata"}'
EOF
chmod +x "$TMP/vendor-bin/apt-cache"
out=$(PATH="$TMP/vendor-bin:$PATH" ROOT="$ROOT" APT_SOURCE_DIR="$TMP/apt" bash -c 'set -o pipefail; source "$ROOT/lib/detection.sh"; vendor_repo_valid google-chrome && vendor_repo_valid vivaldi && echo valid')
check vendor-source-validation "$out" valid
cat > "$TMP/vendor-bin/apt-cache" <<'EOF'
#!/usr/bin/env bash
printf 'Candidate: 1.0\n'
awk 'BEGIN {for (i=0; i<10000; i++) print "unrelated package metadata"}'
EOF
chmod +x "$TMP/vendor-bin/apt-cache"
out=$(PATH="$TMP/vendor-bin:$PATH" ROOT="$ROOT" bash -c 'set -o pipefail; source "$ROOT/lib/detection.sh"; package_candidate example && echo candidate' || true)
check apt-candidate-with-long-policy "$out" candidate
out=$(ROOT="$ROOT" APT_SOURCE_DIR="$TMP/apt" bash -c 'source "$ROOT/lib/detection.sh"; source "$ROOT/lib/planning.sh"; source "$ROOT/lib/package-manager.sh"; source "$ROOT/modules/applications.sh"; vendor_repo_valid() { [[ $1 == google-chrome || $1 == vivaldi ]]; }; plan_browser_repo_cleanup; printf "%s\n" "${ACTION_TITLE[@]}"')
check browser-cleanup-plan "$out" 'Google Chrome repository cleanup'
check browser-cleanup-vivaldi "$out" 'Vivaldi repository cleanup'
out=$(ROOT="$ROOT" APT_SOURCE_DIR="$TMP/apt" HOME="$TMP/home" bash -c '
  source "$ROOT/lib/detection.sh"; source "$ROOT/lib/package-manager.sh"
  vendor_repo_valid() { [[ $1 == google-chrome ]]; }
  refresh_apt() { :; }
  sudo() { "$@"; }
  run_action browser-repo-cleanup google-chrome
  [[ ! -e $APT_SOURCE_DIR/linux-dev-setup-google-chrome.list ]] && echo removed
  find "$HOME/.local/state/linux-dev-setup/repo-backups" -name "linux-dev-setup-google-chrome.list.*" -print
  if run_action browser-repo-cleanup vivaldi; then echo unsafe; fi
  [[ -e $APT_SOURCE_DIR/linux-dev-setup-vivaldi.list ]] && echo retained
' 2>/dev/null)
check browser-cleanup-removes "$out" removed
check browser-cleanup-backup "$out" 'repo-backups/linux-dev-setup-google-chrome.list.'
check browser-cleanup-retains-invalid "$out" retained
[[ $out != *unsafe* ]] || fail 'unverified vendor source caused cleanup'

out=$(ROOT="$ROOT" DS_TEST_MODE=1 DS_TEST_KVM=hidden bash -c 'source "$ROOT/lib/detection.sh"; kvm_state')
check kvm-hidden "$out" hidden
out=$(ROOT="$ROOT" DS_TEST_MODE=1 DS_TEST_KVM=accessible bash -c 'source "$ROOT/lib/detection.sh"; kvm_state')
check kvm-accessible "$out" accessible
cat > "$TMP/mint" <<'EOF'
ID=linuxmint
VERSION_ID=22.3
VERSION_CODENAME=zena
UBUNTU_CODENAME=noble
ID_LIKE="ubuntu debian"
EOF
out=$(DS_TEST_MODE=1 DS_TEST_OS_RELEASE="$TMP/mint" DS_TEST_KVM=hidden DS_TEST_CPU_VIRT=svm bash "$ROOT/install.sh" --module docker --dry-run)
check kvm-namespace "$out" 'device namespace'
[[ $out != *'modprobe kvm'* ]] || fail 'hidden KVM planned modprobe'
[[ $out != *'Engine fallback'* ]] || fail 'hidden KVM suggested Engine fallback'

cat > "$TMP/android.html" <<'EOF'
<tr><td>Linux</td><td>commandlinetools-linux-123_latest.zip</td><td>123 MB</td><td>aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa</td></tr>
<a href="https://dl.google.com/android/repository/commandlinetools-linux-123_latest.zip">Download</a>
EOF
out=$(python3 "$ROOT/scripts/resolve-download.py" android-cli "$TMP/android.html")
check android-cli-resolver "$out" 'commandlinetools-linux-123_latest.zip'
check android-cli-checksum "$out" 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
mkdir -p "$TMP/home/Android/Sdk/platform-tools"
out=$(HOME="$TMP/home" ROOT="$ROOT" bash -c 'source "$ROOT/lib/detection.sh"; android_sdk_root')
check android-sdk-reuse "$out" "$TMP/home/Android/Sdk"
mkdir -p "$TMP/alternate-sdk"
out=$(ANDROID_HOME="$TMP/alternate-sdk" HOME="$TMP/home" ROOT="$ROOT" bash -c 'source "$ROOT/lib/detection.sh"; android_sdk_root' 2>&1) && fail 'conflicting SDK roots accepted'
check android-sdk-conflict "$out" 'Conflicting Android SDK roots'
out=$(HOME="$TMP/home" DS_TEST_MODE=1 DS_TEST_OS_RELEASE="$TMP/mint" DS_TEST_KVM=accessible bash "$ROOT/install.sh" --module android --dry-run)
check android-cli-plan "$out" 'Android Command-line Tools'
check android-platform-plan "$out" 'Android SDK packages'
[[ $out != *'apt-get install -y adb'* ]] || fail 'duplicate ADB planned'
out=$(HOME="$TMP/home" DS_TEST_MODE=1 DS_TEST_OS_RELEASE="$TMP/mint" DS_TEST_KVM=accessible bash "$ROOT/install.sh" --module system,android --dry-run)
[[ $(printf '%s\n' "$out" | grep -c '^  - unzip') == 1 ]] || fail 'duplicate unzip in combined plan'
check android-environment-note "$out" 'set ANDROID_HOME and PATH to verified SDK'
out=$(ROOT="$ROOT" HOME="$TMP/home" DS_TEST_MODE=1 DS_TEST_FORCE_MISSING=unzip bash -c '
  source "$ROOT/lib/detection.sh"; source "$ROOT/lib/planning.sh"; source "$ROOT/modules/android.sh"
  DISTRO=linuxmint; BASE_CODENAME=noble; UBUNTU_CODENAME=noble
  plan_android
  for i in "${!ACTION_TYPE[@]}"; do
    if [[ ${ACTION_TYPE[i]} == android-cli ]]; then
      dep=${ACTION_DEP[i]}
      if [[ $dep == - ]]; then echo 'dep-title=none'; else printf 'dep-title=%s\n' "${ACTION_TITLE[dep]}"; fi
    fi
  done
')
check android-unzip-dependency "$out" 'dep-title=unzip'
out=$(ROOT="$ROOT" HOME="$TMP/home" bash -c 'source "$ROOT/lib/package-manager.sh"; run_action android-cli "$HOME/Android/Sdk" || echo "result=$?"' 2>&1)
check android-license-deferred "$out" result=3
out=$(ROOT="$ROOT" bash -c '
  source "$ROOT/lib/package-manager.sh"
  printf "%s\n" "platforms;android-36 | Android 16" "platforms;android-37.0 | Android 17" "build-tools;36.0.0 | stable" "build-tools;38.0.0-rc1 | preview" | android_stable_packages
')
check android-stable-platform "$out" 'platforms;android-37.0'
check android-stable-build-tools "$out" 'build-tools;36.0.0'
[[ $out != *rc1* ]] || fail 'preview Build Tools selected'
mkdir -p "$TMP/sdk/cmdline-tools/latest/bin" "$TMP/sdk/platform-tools"
printf '#!/bin/sh\nexit 0\n' > "$TMP/sdk/platform-tools/adb"
chmod +x "$TMP/sdk/platform-tools/adb"
cat > "$TMP/sdk/cmdline-tools/latest/bin/sdkmanager" <<'EOF'
#!/usr/bin/env bash
case " $* " in
  *' --licenses '*) echo 'license prompt';;
  *' --list '*) printf '%s\n' 'platforms;android-37.0 | Android 17' 'build-tools;36.0.0 | stable';;
  *' --install '*) echo 'install prompt'; mkdir -p "$SDK_TMP/sdk/platforms/android-37.0" "$SDK_TMP/sdk/build-tools/36.0.0";;
esac
EOF
chmod +x "$TMP/sdk/cmdline-tools/latest/bin/sdkmanager"
cat > "$TMP/run-sdk-test.sh" <<'EOF'
#!/usr/bin/env bash
source "$ROOT/lib/package-manager.sh"
run_action android-sdk-packages "$SDK_TMP/sdk" >"$SDK_TMP/run.log" 2>&1
EOF
chmod +x "$TMP/run-sdk-test.sh"
out=$(HOME="$TMP/home" ROOT="$ROOT" SDK_TMP="$TMP" script -qec "$TMP/run-sdk-test.sh" /dev/null)
check android-visible-license-prompt "$out" 'license prompt'
check android-visible-install-prompt "$out" 'install prompt'

out=$(HOME="$TMP/home" ROOT="$ROOT" bash "$ROOT/install.sh" --checklist --dry-run)
check checklist-dry-run "$out" 'Guided setup checklist'
check checklist-browser-detail "$out" 'Optional profile and account sync review'
[[ $out != *'Google Chrome              pending'* ]] || fail 'optional browser falsely pending'
[[ ! -e "$TMP/home/.local/state/linux-dev-setup/checklist.done" ]] || fail 'checklist dry-run wrote progress'
out=$(HOME="$TMP/home" ROOT="$ROOT" bash -c 'source "$ROOT/lib/checklist.sh"; checklist_mark chrome; checklist_status chrome 1')
check checklist-mark-resume "$out" marked
out=$(HOME="$TMP/home" ROOT="$ROOT" bash -c 'source "$ROOT/lib/checklist.sh"; checklist_mark gh; checklist_probed() { return 0; }; checklist_status gh 1')
check checklist-probe-overrides-mark "$out" ready
mkdir -p "$TMP/fake-bin"
cat > "$TMP/fake-bin/x-terminal-emulator" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CHECKLIST_LAUNCH_LOG"
EOF
chmod +x "$TMP/fake-bin/x-terminal-emulator"
cat > "$TMP/run-checklist-test.sh" <<'EOF'
#!/usr/bin/env bash
source "$ROOT/lib/detection.sh"
source "$ROOT/lib/checklist.sh"
checklist_catalog() { CHECKLIST_IDS=(gh); CHECKLIST_NAMES=('GitHub CLI'); CHECKLIST_KINDS=(cli); }
checklist_probed() { return 1; }
run_checklist 0
EOF
chmod +x "$TMP/run-checklist-test.sh"
out=$(printf '1\n\n0\n' | HOME="$TMP/home" ROOT="$ROOT" CHECKLIST_LAUNCH_LOG="$TMP/launch.log" PATH="$TMP/fake-bin:$PATH" script -qec "$TMP/run-checklist-test.sh" /dev/null)
check checklist-return-to-menu "$out" 'Still pending according to the tool'
[[ $(grep -c 'checklist-terminal.sh gh' "$TMP/launch.log") == 1 ]] || fail 'checklist did not launch one terminal for selected item'
echo 'ok - checklist-terminal-launch'
