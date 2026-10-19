#!/usr/bin/env bash
plan_docker() {
  local kvm_dep=- kvm_module=''
  kvm_module=$(cpu_kvm_module || true)
  local kvm_status; kvm_status=$(kvm_state)
  if (( INSTALL_DOCKER_DESKTOP )) && [[ $kvm_status == hidden ]]; then
    plan_manual 'Docker Desktop KVM device namespace' 'KVM is registered by the kernel but /dev/kvm is hidden in this environment; run the installer on the host or expose the device'
  elif (( INSTALL_DOCKER_DESKTOP )) && ! has_kvm && [[ -n $kvm_module ]]; then
    kvm_dep=${#ACTION_TYPE[@]}
    add_action configure 'Load KVM modules' kvm-setup "$kvm_module" - 'sudo modprobe; verify /dev/kvm; add user to kvm group only if needed; new login may be required'
  elif (( INSTALL_DOCKER_DESKTOP )) && has_kvm && ! kvm_access; then
    kvm_dep=${#ACTION_TYPE[@]}
    add_action configure 'KVM device access' kvm-setup "$kvm_module" - 'Check /dev/kvm permissions; add user to kvm group if needed; new login may be required'
  fi
  if package_installed docker-desktop; then
    add_action installed 'Docker Desktop' none '' - 'Existing installation retained; verify desktop-linux with docker context ls'
  elif (( INSTALL_DOCKER_DESKTOP )) && { has_kvm || [[ $kvm_dep != - ]]; } && [[ $(ubuntu_compat_version) == 24.04 || $(ubuntu_compat_version) == 26.04 ]]; then
    if [[ -n ${DOCKER_DESKTOP_DEB:-} && -n ${DOCKER_DESKTOP_SHA256:-} ]]; then
      local repo_index=$kvm_dep
      if ! repo_present docker; then
        ensure_repo_tools_planned
        repo_index=${#ACTION_TYPE[@]}
        add_action configure 'Docker repository' repo docker "$REPLY" 'Official signed Ubuntu APT repository using the base codename'
      fi
      add_action install 'Docker Desktop' docker-desktop "$DOCKER_DESKTOP_DEB" "$repo_index" 'Verify supplied official .deb against release-notes SHA-256; install with APT; launch and accept terms'
    else
      local repo_index=$kvm_dep
      if ! repo_present docker; then
        ensure_repo_tools_planned
        repo_index=${#ACTION_TYPE[@]}
        add_action configure 'Docker repository' repo docker "$REPLY" 'Official signed Ubuntu APT repository using the base codename'
      fi
      add_action install 'Docker Desktop' docker-desktop auto "$repo_index" 'download official .deb and checksum from Docker release notes; verify SHA-256 before APT installation'
    fi
  elif (( INSTALL_DOCKER_DESKTOP )) && [[ $kvm_status != hidden ]]; then
    if [[ -z $kvm_module ]]; then
      plan_manual 'Docker Desktop requires KVM' 'CPU virtualization flag svm/vmx is not exposed to Linux. Enable SVM/AMD-V or VT-x in firmware (or expose nested virtualization), reboot, then rerun; diagnose.sh shows details.'
    else
      plan_manual 'Docker Desktop requires KVM' 'Check /dev/kvm and user permissions; run diagnose.sh. Docker Desktop cannot start until KVM works.'
    fi
  elif (( ! INSTALL_DOCKER_DESKTOP )); then add_action skipped 'Docker Desktop' none '' - 'Disabled in settings'; fi
  if package_installed docker-ce || package_installed docker.io; then
    add_action installed 'Docker CLI / Engine' none docker - 'Existing Engine package retained; inspect docker context ls'
  elif (( INSTALL_DOCKER_ENGINE_FALLBACK )) && [[ $kvm_status == missing && $kvm_dep == - ]] && ! package_installed docker-desktop && ! package_installed containerd && ! package_installed runc && ! package_installed podman-docker && [[ $BASE_CODENAME == noble || $BASE_CODENAME == jammy || $BASE_CODENAME == resolute ]]; then
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
  elif [[ $kvm_status != hidden ]]; then
    plan_note 'Explicit Engine fallback' 'If KVM cannot be enabled, opt in with INSTALL_DOCKER_ENGINE_FALLBACK=1; uses Docker official Ubuntu APT source with the noble base on Mint. Review conflicts first.'
  fi
  if has_command docker; then
    if docker compose version >/dev/null 2>&1; then add_action installed 'Docker Compose plugin' none '' - 'Existing installation retained'
    else plan_manual 'Docker Compose plugin' 'Check installed Engine source before adding a plugin'; fi
    if docker buildx version >/dev/null 2>&1; then add_action installed 'Docker Buildx plugin' none '' - 'Existing installation retained'
    else plan_manual 'Docker Buildx plugin' 'Check installed Engine source before adding a plugin'; fi
  fi
  plan_note 'Docker contexts' 'Use docker context ls; desktop-linux and default have separate images, containers and volumes. Do not run both daemons on the same published ports.'
}
