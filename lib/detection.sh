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
docker_engine_supported() {
  case "$DISTRO:$DISTRO_VERSION" in
    ubuntu:22.04|ubuntu:24.04|ubuntu:26.04|debian:12|debian:13) return 0;;
    *) return 1;;
  esac
}
has_command() { command -v "$1" >/dev/null 2>&1; }
package_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'; }
package_version() { dpkg-query -W -f='${Version}' "$1" 2>/dev/null || true; }
package_candidate() { apt-cache policy "$1" 2>/dev/null | grep -Eq 'Candidate: [^ (]'; }
flatpak_installed() { has_command flatpak && flatpak info "$1" >/dev/null 2>&1; }
has_kvm() { [[ -e /dev/kvm ]]; }
repo_present() {
  local needle
  case $1 in
    github-cli) needle=cli.github.com/packages;;
    warp) needle=releases.warp.dev/linux/deb;;
    docker) needle=download.docker.com/linux/;;
    claude-desktop) needle=downloads.claude.ai/claude-desktop/apt/stable;;
    *) return 1;;
  esac
  grep -RqsF "$needle" /etc/apt/sources.list.d /etc/apt/sources.list 2>/dev/null
}
