#!/usr/bin/env bash
plan_android() {
  if has_command javac; then add_action installed 'JDK' none javac - "$(javac -version 2>&1)"
  else plan_apt 'OpenJDK 17' openjdk-17-jdk javac; fi
  local unzip_dep=- i unzip_seen=0
  for i in "${!ACTION_TITLE[@]}"; do
    if [[ ${ACTION_TITLE[i]} == unzip ]]; then unzip_seen=1; break; fi
  done
  (( unzip_seen )) || plan_apt unzip unzip unzip
  for i in "${!ACTION_TYPE[@]}"; do
    if [[ ${ACTION_TYPE[i]} == apt && ${ACTION_ARG[i]} == unzip ]]; then unzip_dep=$i; break; fi
  done
  if [[ -x /opt/android-studio/bin/studio || -x $HOME/.local/share/android-studio/bin/studio ]]; then
    add_action installed 'Android Studio' none '' - 'Existing installation retained'
  elif [[ -n ${ANDROID_STUDIO_TARBALL:-} && -n ${ANDROID_STUDIO_SHA256:-} ]]; then
    add_action install 'Android Studio' android-studio "$ANDROID_STUDIO_TARBALL" - 'Verify Google Linux tarball SHA-256, extract to user applications, and launch Setup Wizard'
  else
    add_action install 'Android Studio' android-studio auto - 'download verified Android Studio tarball using Google-published SHA-256; launch Setup Wizard'
  fi
  local sdk='' cli_dep=- packages_dep=-
  if ! sdk=$(android_sdk_root); then
    plan_manual 'Android SDK root' 'ANDROID_HOME, ANDROID_SDK_ROOT and existing SDK directories conflict; select one location before installation'
  else
    if [[ -x $sdk/cmdline-tools/latest/bin/sdkmanager ]]; then
      add_action installed 'Android Command-line Tools' none "$sdk" - 'Existing SDK manager retained'
    else
      cli_dep=${#ACTION_TYPE[@]}
      add_action install 'Android Command-line Tools' android-cli "$sdk" "$unzip_dep" 'Verify Google ZIP against published SHA-256; accept download terms interactively'
    fi
    packages_dep=${#ACTION_TYPE[@]}
    add_action configure 'Android SDK packages' android-sdk-packages "$sdk" "$cli_dep" 'Use SDK Manager for Platform Tools, newest stable platform and Build Tools; prompt for licenses'
    if [[ -f $HOME/.profile ]] && grep -Fq "export ANDROID_HOME=\"$sdk\"" "$HOME/.profile"; then
      add_action installed 'Android environment' none "$sdk" - 'Existing profile points at selected SDK'
    else
      add_action configure 'Android environment' android-env "$sdk" "$packages_dep" 'Back up ~/.profile; set ANDROID_HOME and PATH to verified SDK'
    fi
  fi
  if [[ $(kvm_state) == hidden ]]; then
    local docker_kvm_note=0
    for i in "${!ACTION_TITLE[@]}"; do [[ ${ACTION_TITLE[i]} != 'Docker Desktop KVM device namespace' ]] || docker_kvm_note=1; done
    if (( docker_kvm_note )); then plan_note KVM 'Docker module already reports the hidden device namespace'
    else plan_manual KVM 'Kernel registered KVM, but /dev/kvm is hidden in this device namespace; run on host or expose device'; fi
  elif has_kvm; then add_action installed KVM none '' - '/dev/kvm present'
  else
    local kvm_planned=0 i module
    for i in "${!ACTION_TYPE[@]}"; do [[ ${ACTION_TYPE[i]} != kvm-setup ]] || kvm_planned=1; done
    module=$(cpu_kvm_module || true)
    if (( kvm_planned )); then plan_note KVM 'Docker module already plans KVM setup for the Android emulator'
    elif [[ -n $module ]]; then add_action configure 'Load KVM modules for Android emulator' kvm-setup "$module" - 'sudo modprobe; verify /dev/kvm; configure kvm group access'
    else plan_manual KVM 'CPU virtualization flag svm/vmx is not exposed; enable it in firmware and reboot for emulator acceleration'; fi
  fi
  plan_manual 'Android devices' 'Review udev permissions before connecting a device'
}
