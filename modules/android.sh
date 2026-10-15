#!/usr/bin/env bash
plan_android() {
  if has_command javac; then
    local version; version=$(javac -version 2>&1 || true)
    if [[ $version == 'javac 17.'* || $version == 'javac 17' ]]; then
      add_action installed 'JDK 17' none javac - "$version"
    else plan_manual 'JDK 17' "Existing $version; verify project Gradle compatibility before adding another JDK"; fi
  else plan_apt 'OpenJDK 17' openjdk-17-jdk javac; fi
  if has_command adb || [[ -x $HOME/Android/Sdk/platform-tools/adb ]]; then
    add_action installed ADB none adb - 'Existing installation retained'
  else plan_apt ADB adb adb; fi
  if [[ -x $HOME/Android/Sdk/platform-tools/adb ]]; then
    add_action installed 'Android SDK Platform Tools' none '' - 'Existing SDK retained'
  else plan_manual 'Android SDK Platform Tools' 'Install through Android Studio SDK Manager to avoid a duplicate SDK tree'; fi
  if [[ -x $HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager ]]; then
    add_action installed 'Android SDK command-line tools' none '' - 'Existing SDK retained'
  else plan_manual 'Android SDK command-line tools' 'Install via Android Studio SDK Manager, accepting licenses interactively'; fi
  if [[ -x /opt/android-studio/bin/studio || -x $HOME/.local/share/JetBrains/Toolbox/apps/android-studio/bin/studio ]]; then
    add_action installed 'Android Studio' none '' - 'Existing installation retained'
  else plan_manual 'Android Studio' 'Download official Linux tarball and checksum from https://developer.android.com/studio; run Setup Wizard for SDK'; fi
  if [[ -f $HOME/.profile ]] && grep -Fq '# linux-dev-setup managed block' "$HOME/.profile"; then
    add_action installed 'Android environment' none '' - 'Managed block exists'
  else add_action configure 'Android environment' android-env '' - 'Backup ~/.profile; set ANDROID_HOME and PATH'; fi
  if [[ -e /dev/kvm ]]; then add_action installed KVM none '' - '/dev/kvm present'
  else plan_manual KVM 'Check AMD-V/SVM in firmware and user permission on /dev/kvm; no BIOS changes are made'; fi
  plan_manual 'Android devices' 'Review udev permissions before connecting a device; no blanket USB rule is installed'
}
