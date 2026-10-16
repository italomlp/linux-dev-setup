#!/usr/bin/env bash
plan_android() {
  if has_command javac; then add_action installed 'JDK' none javac - "$(javac -version 2>&1)"
  else plan_apt 'OpenJDK 17' openjdk-17-jdk javac; fi
  local sdk=''
  sdk=$(sdk_directory || true)
  if [[ -n $sdk ]]; then
    add_action installed 'Android SDK at' none "$sdk" - 'Platform Tools and Command-line Tools detected'
    if [[ -f $HOME/.profile ]] && grep -Fq "export ANDROID_HOME=\"$sdk\"" "$HOME/.profile"; then
      add_action installed 'Android environment' none "$sdk" - 'Existing profile points at detected SDK'
    else
      add_action configure 'Android environment' android-env "$sdk" - 'Back up ~/.profile; set ANDROID_HOME and PATH to detected SDK'
    fi
  else
    plan_manual 'Android Studio Setup Wizard' 'Launch Studio, complete Setup Wizard, install SDK Platform Tools and Android SDK Command-line Tools in SDK Manager, and accept licenses there; rerun to detect SDK'
  fi
  if [[ -x /opt/android-studio/bin/studio || -x $HOME/.local/share/android-studio/bin/studio ]]; then
    add_action installed 'Android Studio' none '' - 'Existing installation retained'
  elif [[ -n ${ANDROID_STUDIO_TARBALL:-} && -n ${ANDROID_STUDIO_SHA256:-} ]]; then
    add_action install 'Android Studio' android-studio "$ANDROID_STUDIO_TARBALL" - 'Verify Google Linux tarball SHA-256, extract to user applications, and launch Setup Wizard'
  else
    add_action install 'Android Studio' android-studio auto - 'download verified Android Studio tarball using Google-published SHA-256; launch Setup Wizard'
  fi
  if has_kvm; then add_action installed KVM none '' - '/dev/kvm present'
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
