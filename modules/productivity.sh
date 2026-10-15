#!/usr/bin/env bash
plan_productivity() {
  local desktop_lower; desktop_lower=$(printf '%s' "$DESKTOP" | tr '[:upper:]' '[:lower:]')
  case $desktop_lower in
    *gnome*)
      plan_apt 'GNOME Tweaks' gnome-tweaks gnome-tweaks
      plan_apt 'Extension Manager' gnome-shell-extension-manager extension-manager;;
    *) add_action skipped 'GNOME utilities' none '' - "Desktop is $DESKTOP";;
  esac
  plan_apt 'KDE Connect' kdeconnect kdeconnect-cli
  plan_apt Restic restic restic
  if has_command timeshift || has_command snapper; then
    add_action installed 'Snapshot tool' none '' - 'Existing installation retained; layout not modified'
  else plan_manual 'Timeshift or Snapper' 'Inspect Btrfs subvolumes and snapshot layout before choosing and configuring a tool'; fi
  plan_manual 'Backup destination' 'Configure restic repository only after selecting a destination and retention policy'
}
