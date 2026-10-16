#!/usr/bin/env bash
detect_system() {
  local release=/etc/os-release
  if [[ ${DS_TEST_MODE:-0} == 1 && -n ${DS_TEST_OS_RELEASE:-} ]]; then release=$DS_TEST_OS_RELEASE; fi
  [[ -r $release ]] || { echo 'Missing os-release' >&2; return 1; }
  # shellcheck disable=SC1090
  . "$release"
  DISTRO=${ID:-unknown}; DISTRO_VERSION=${VERSION_ID:-unknown}
  BASE_CODENAME=${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}
  ARCH=$(uname -m)
  if [[ ${DS_TEST_MODE:-0} == 1 && -n ${DS_TEST_ARCH:-} ]]; then ARCH=$DS_TEST_ARCH; fi
  DESKTOP=${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}
  case $DISTRO in
    ubuntu|debian|linuxmint|pop|zorin) ;;
    *) echo "Unsupported distribution: $DISTRO" >&2; return 1 ;;
  esac
  [[ $ARCH == x86_64 ]] || { echo "Unsupported architecture: $ARCH" >&2; return 1; }
  if [[ ${DS_TEST_MODE:-0} != 1 ]]; then
    command -v apt-get >/dev/null || { echo 'APT is required' >&2; return 1; }
  fi
}
is_native_distro() { [[ $DISTRO == ubuntu || $DISTRO == debian ]]; }
is_ubuntu_based() { [[ $DISTRO == ubuntu || ( -n ${UBUNTU_CODENAME:-} && $ID_LIKE == *ubuntu* ) || $DISTRO == linuxmint || $DISTRO == pop || $DISTRO == zorin ]]; }
ubuntu_compat_version() {
  case ${UBUNTU_CODENAME:-} in
    jammy) printf '22.04';;
    noble) printf '24.04';;
    resolute) printf '26.04';;
    *) [[ $DISTRO == ubuntu ]] && printf '%s' "$DISTRO_VERSION";;
  esac
}
docker_engine_supported() {
  case "$DISTRO:$DISTRO_VERSION" in
    ubuntu:22.04|ubuntu:24.04|ubuntu:26.04|debian:12|debian:13) return 0;;
    *) return 1;;
  esac
}
test_force_missing() { [[ ${DS_TEST_MODE:-0} == 1 && ",${DS_TEST_FORCE_MISSING:-}," == *",$1,"* ]]; }
has_command() { ! test_force_missing "$1" && command -v "$1" >/dev/null 2>&1; }
package_installed() { ! test_force_missing "$1" && dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'; }
package_version() { dpkg-query -W -f='${Version}' "$1" 2>/dev/null || true; }
package_candidate() {
  if [[ -n ${APT_SOURCE_PARTS_OVERRIDE:-} ]]; then
    apt-cache -o "Dir::Etc::sourceparts=$APT_SOURCE_PARTS_OVERRIDE" policy "$1" 2>/dev/null | grep -Eq 'Candidate: [^ (]'
  else
    apt-cache policy "$1" 2>/dev/null | grep -Eq 'Candidate: [^ (]'
  fi
}
flatpak_installed() { has_command flatpak && flatpak info "$1" >/dev/null 2>&1; }
has_kvm() {
  if [[ ${DS_TEST_MODE:-0} == 1 && -n ${DS_TEST_KVM:-} ]]; then [[ $DS_TEST_KVM == present ]]; return; fi
  [[ -c /dev/kvm ]]
}
kvm_access() { [[ -r /dev/kvm && -w /dev/kvm ]]; }
cpu_kvm_module() {
  local flag=''
  if [[ ${DS_TEST_MODE:-0} == 1 && -n ${DS_TEST_CPU_VIRT:-} ]]; then flag=$DS_TEST_CPU_VIRT
  elif grep -qm1 -w svm /proc/cpuinfo; then flag=svm
  elif grep -qm1 -w vmx /proc/cpuinfo; then flag=vmx
  fi
  case $flag in
    svm) printf kvm_amd;;
    vmx) printf kvm_intel;;
    *) return 1;;
  esac
}
sdk_directory() {
  local path
  for path in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "$HOME/Android/sdk"; do
    [[ -n $path && -x $path/platform-tools/adb && -x $path/cmdline-tools/latest/bin/sdkmanager ]] && { printf '%s' "$path"; return 0; }
  done
  return 1
}
repo_present() {
  [[ ${DS_TEST_MODE:-0} != 1 || ${DS_TEST_IGNORE_REPOS:-0} != 1 ]] || return 1
  local needle
  case $1 in
    github-cli) needle=cli.github.com/packages;;
    warp) needle=releases.warp.dev/linux/deb;;
    docker) needle=download.docker.com/linux/;;
    claude-desktop) needle=downloads.claude.ai/claude-desktop/apt/stable;;
    tailscale) needle=pkgs.tailscale.com/stable/ubuntu;;
    google-chrome) needle=dl.google.com/linux/chrome/deb;;
    vivaldi) needle=repo.vivaldi.com/archive/deb;;
    dbeaver) needle=dbeaver.io/debs/dbeaver-ce;;
    bruno) needle=debian.usebruno.com;;
    *) return 1;;
  esac
  grep -RqsF "$needle" /etc/apt/sources.list.d /etc/apt/sources.list 2>/dev/null
}
