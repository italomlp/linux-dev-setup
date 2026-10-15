#!/usr/bin/env bash
plan_docker() {
  if package_installed docker-ce || package_installed docker.io; then
    add_action installed 'Docker CLI / Engine' none docker - 'Existing Engine package retained; inspect docker context ls'
  elif has_command docker; then
    plan_manual 'Docker Engine' 'Docker CLI exists without a detected Engine package; inspect docker context ls and package origin before adding another daemon'
  elif package_installed containerd || package_installed runc || package_installed podman-docker; then
    plan_manual 'Docker Engine' 'Conflicting container runtime package is installed; review migration before changing packages'
  elif docker_engine_supported && [[ -n $BASE_CODENAME ]]; then
    local repo_index=-
    if repo_present docker; then
      add_action installed 'Docker repository' none '' - 'Existing APT source retained'
    else
      ensure_repo_tools_planned
      local tools_index=$REPLY
      repo_index=${#ACTION_TYPE[@]}
      add_action configure 'Docker repository' repo docker "$tools_index" 'sudo; official signed stable repository'
    fi
    for package in docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin; do
      add_action install "$package" apt "$package" "$repo_index" 'sudo; Docker official APT repository'
    done
  else
    plan_manual 'Docker Engine' 'Docker does not officially support this derivative; inspect its Ubuntu/Debian base and existing packages before selecting repository'
  fi
  if has_command docker; then
    if docker compose version >/dev/null 2>&1; then add_action installed 'Docker Compose plugin' none '' - 'Existing installation retained'
    else plan_manual 'Docker Compose plugin' 'Check installed Engine source before adding a plugin'; fi
    if docker buildx version >/dev/null 2>&1; then add_action installed 'Docker Buildx plugin' none '' - 'Existing installation retained'
    else plan_manual 'Docker Buildx plugin' 'Check installed Engine source before adding a plugin'; fi
  fi
  if (( INSTALL_DOCKER_DESKTOP )); then
    if package_installed docker-desktop; then add_action installed 'Docker Desktop' none '' - 'Existing installation retained'
    elif docker_engine_supported && has_kvm; then
      plan_manual 'Docker Desktop' 'Download official versioned .deb and checksum, then sudo apt install ./docker-desktop-amd64.deb; https://docs.docker.com/desktop/setup/install/linux/'
    else
      plan_manual 'Docker Desktop' 'Requires supported Ubuntu/Debian release and KVM; verify /dev/kvm, then follow https://docs.docker.com/desktop/setup/install/linux/'
    fi
  else add_action skipped 'Docker Desktop' none '' - 'Disabled in settings'; fi
  plan_manual 'Docker contexts' 'Use docker context ls; desktop-linux and default have separate images, containers and volumes. Do not run both daemons on the same published ports.'
}
