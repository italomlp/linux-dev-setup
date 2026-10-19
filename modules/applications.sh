#!/usr/bin/env bash
plan_applications() {
  plan_browser_repo_cleanup
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
  else plan_repo_package Vivaldi vivaldi-stable vivaldi vivaldi; fi
  if has_command google-chrome || package_installed google-chrome-stable; then add_action installed 'Google Chrome' none '' - 'Existing installation retained'
  else plan_repo_package 'Google Chrome' google-chrome-stable google-chrome google-chrome; fi
  if has_command tailscale; then add_action installed Tailscale none '' - 'Existing installation retained; authentication stays manual'
  else plan_repo_package Tailscale tailscale tailscale tailscale; fi
  if has_command dbeaver || package_installed dbeaver-ce; then add_action installed DBeaver none dbeaver - 'Existing installation retained'
  else plan_repo_package DBeaver dbeaver-ce dbeaver dbeaver; fi
  if has_command bruno || package_installed bruno; then add_action installed Bruno none bruno - 'Existing installation retained'
  else plan_repo_package Bruno bruno bruno bruno; fi
  if has_command slack || package_installed slack-desktop; then add_action installed Slack none slack - 'Existing installation retained'
  else
    plan_known_apt 'Slack signature verifier' debsig-verify debsig-verify
    local slack_sig_dep=-
    if [[ ${ACTION_STATUS[-1]} == install ]]; then slack_sig_dep=$((${#ACTION_TYPE[@]}-1)); fi
    add_action configure 'Slack package signature policy' slack-signature '' "$slack_sig_dep" 'install Slack signing key and debsig policy'
    local slack_policy_dep=$((${#ACTION_TYPE[@]}-1))
    add_action install Slack slack-deb '' "$slack_policy_dep" 'download official .deb, verify Slack signature, install with APT'
  fi
}
plan_browser_repo_cleanup() {
  local name label file
  for name in google-chrome vivaldi; do
    file="$(apt_source_dir)/linux-dev-setup-$name.list"
    [[ -f $file ]] || continue
    vendor_repo_valid "$name" || continue
    case $name in google-chrome) label='Google Chrome';; vivaldi) label=Vivaldi;; esac
    add_action configure "$label repository cleanup" browser-repo-cleanup "$name" - 'Back up and remove redundant installer source; retain vendor source and signing key'
  done
}
