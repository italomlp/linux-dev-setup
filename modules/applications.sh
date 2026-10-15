#!/usr/bin/env bash
plan_applications() {
  if (( INSTALL_FLATPAK )); then
    local flatpak_dep=- flathub_dep=-
    if has_command flatpak; then add_action installed Flatpak none '' - 'Existing installation retained'
    else
      plan_apt Flatpak flatpak flatpak
      flatpak_dep=$((${#ACTION_TYPE[@]}-1))
    fi
    if has_command flatpak && flatpak remotes --user --columns=name 2>/dev/null | grep -qx flathub; then
      add_action installed Flathub none '' - 'User remote exists'
    else
      add_action configure Flathub flatpak-remote '' "$flatpak_dep" 'User remote from https://flathub.org/setup'
      flathub_dep=$((${#ACTION_TYPE[@]}-1))
    fi
    if has_command zen || has_command zen-bin || flatpak_installed app.zen_browser.zen; then
      add_action installed 'Zen Browser' none '' - 'Existing installation retained'
    else add_action install 'Zen Browser' flatpak app.zen_browser.zen "$flathub_dep" 'Official Flathub package; user installation'; fi
  else add_action skipped 'Zen Browser Flatpak' none '' - 'Flatpak disabled in settings'; fi
  if has_command vivaldi || package_installed vivaldi-stable; then add_action installed Vivaldi none '' - 'Existing installation retained'
  else plan_manual Vivaldi 'Official .deb configures signed update repository; https://vivaldi.com/download/'; fi
  if has_command google-chrome || package_installed google-chrome-stable; then add_action installed 'Google Chrome' none '' - 'Existing installation retained'
  else plan_manual 'Google Chrome' 'Official 64-bit .deb: https://www.google.com/chrome/'; fi
  if has_command tailscale; then add_action installed Tailscale none '' - 'Existing installation retained; authentication stays manual'
  else plan_manual Tailscale 'Use official stable APT instructions for this distribution: https://tailscale.com/docs/install/linux'; fi
}
