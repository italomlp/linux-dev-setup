#!/usr/bin/env bash
declare -a ACTION_STATUS=() ACTION_TITLE=() ACTION_TYPE=() ACTION_ARG=() ACTION_DEP=() ACTION_NOTE=() ACTION_RESULT=()
add_action() {
  ACTION_STATUS+=("$1"); ACTION_TITLE+=("$2"); ACTION_TYPE+=("$3")
  ACTION_ARG+=("${4:-}"); ACTION_DEP+=("${5:--}"); ACTION_NOTE+=("${6:-}")
  ACTION_RESULT+=(pending)
}
plan_apt() {
  local title=$1 package=$2 binary=${3:-}
  local i
  for i in "${!ACTION_TYPE[@]}"; do
    [[ ${ACTION_TYPE[i]} == apt && ${ACTION_ARG[i]} == "$package" ]] && return 0
  done
  if { [[ -n $binary ]] && has_command "$binary"; } || package_installed "$package"; then
    local version; version=$(package_version "$package")
    add_action installed "$title" none "${binary:-$package}" - "Existing installation retained${version:+ (APT $version)}"
  elif package_candidate "$package"; then
    add_action install "$title" apt "$package" - 'sudo apt-get install'
  else
    add_action manual "$title" none "$package" - 'No APT candidate in current repositories; check distribution support'
  fi
}
plan_known_apt() {
  local title=$1 package=$2 binary=${3:-}
  if { [[ -n $binary ]] && has_command "$binary"; } || package_installed "$package"; then
    add_action installed "$title" none "${binary:-$package}" - 'Existing installation retained'
  else
    add_action install "$title" apt "$package" - 'sudo apt-get install'
  fi
}
ensure_repo_tools_planned() {
  local i
  for i in "${!ACTION_TYPE[@]}"; do
    if [[ ${ACTION_TYPE[i]} == repo-tools ]]; then REPLY=$i; return 0; fi
  done
  REPLY=${#ACTION_TYPE[@]}
  add_action install 'APT repository prerequisites' repo-tools '' - 'sudo apt-get install ca-certificates curl gnupg'
}
plan_manual() { add_action manual "$1" none '' - "$2"; }
plan_note() { add_action note "$1" none '' - "$2"; }
plan_flatpak() {
  local title=$1 app=$2
  if flatpak_installed "$app"; then add_action installed "$title" none "$app" - 'Flatpak already installed'
  elif has_command flatpak; then add_action install "$title" flatpak "$app" - 'Flathub user installation'
  else add_action manual "$title" none "$app" - 'Install Flatpak and Flathub first'; fi
}
plan_repo_package() {
  local title=$1 package=$2 binary=$3 repo=$4
  if has_command "$binary" || package_installed "$package"; then
    add_action installed "$title" none "$binary" - 'Existing installation retained'
  else
    local idx=-
    if repo_present "$repo"; then
      add_action installed "$repo repository" none '' - 'Existing APT source retained'
    else
      ensure_repo_tools_planned
      local tools_index=$REPLY
      idx=${#ACTION_TYPE[@]}
      add_action configure "$repo repository" repo "$repo" "$tools_index" 'sudo; official signed APT repository'
    fi
    add_action install "$title" apt "$package" "$idx" 'sudo apt-get install after repository setup'
  fi
}
describe_action() {
  local type=$1 arg=$2
  case $type in
    apt) printf 'sudo apt-get update; sudo apt-get install -y %q' "$arg";;
    repo) printf 'configure signed %s APT repository (sudo)' "$arg";;
    browser-repo-cleanup) printf 'back up and remove redundant installer-owned %s APT source (sudo)' "$arg";;
    repo-tools) printf 'sudo apt-get install -y ca-certificates curl gnupg';;
    slack-signature) printf 'configure Slack debsig verification key and policy';;
    slack-deb) printf 'download official Slack .deb, verify package signature, install with APT';;
    flatpak) printf 'flatpak install --user -y flathub %q' "$arg";;
    flatpak-remote) printf 'flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo';;
    mise-tool) printf 'mise use -g %q' "$arg";;
    npm) printf 'mise exec node@lts -- npm install -g %q' "$arg";;
    shell-zsh) printf 'backup and append managed block to ~/.zshrc';;
    shell-bash) printf 'backup and append managed block to ~/.bashrc';;
    android-env) printf 'backup and append managed block to ~/.profile';;
    android-studio) if [[ $arg == auto ]]; then printf 'download Google Linux tarball and published SHA-256; verify; launch Setup Wizard'; else printf 'verify SHA-256 and extract Android Studio tarball; launch Setup Wizard'; fi;;
    android-cli) printf 'download Google Command-line Tools ZIP, verify SHA-256 and install in %q' "$arg";;
    android-sdk-packages) printf 'install Platform Tools, newest stable platform and Build Tools in %q using sdkmanager' "$arg";;
    docker-desktop) if [[ $arg == auto ]]; then printf 'download official .deb and checksum; verify SHA-256; sudo apt-get install'; else printf 'verify SHA-256 and sudo apt-get install official Docker Desktop .deb'; fi;;
    login-zsh) printf 'chsh -s %q (interactive)' "$arg";;
    release-tar) printf 'verify official archive SHA-256 and install %q in ~/.local/bin' "${arg%%:*}";;
    github-release-tar) printf 'download official %q release and verify GitHub SHA-256 digest' "$arg";;
    chatgpt-deb) printf 'download official ChatGPT .deb over HTTPS; inspect package; sudo apt-get install';;
    claude-repo-repair) printf 'remove duplicate installer Claude APT source; refresh APT';;
    antigravity-ide) printf 'download official Antigravity IDE Linux tarball over HTTPS and install for user';;
    antigravity-cli) printf 'download Antigravity CLI and verify vendor SHA-512 manifest';;
    llama-vulkan) printf 'download official Ubuntu Vulkan release and verify GitHub SHA-256 digest';;
    ollama-release) printf 'download official Linux archive, verify GitHub SHA-256 digest, install systemd service';;
    gpu-check) printf 'vulkaninfo --summary; llama-cli --list-devices';;
    kvm-setup) printf 'sudo modprobe kvm and %q; verify /dev/kvm; configure kvm group access' "$arg";;
  esac
}
print_plan() {
  local i status label count mode
  mode='Installation plan'
  [[ ${DRY_RUN:-0} != 1 ]] || mode='Dry run'
  ui_heading 'Linux Dev Setup' "$mode"
  printf 'System: %s %s | base: %s | architecture: %s | desktop: %s\n' "$DISTRO" "$DISTRO_VERSION" "${BASE_CODENAME:-unknown}" "$ARCH" "$DESKTOP"
  printf 'Modules: %s\n' "${SELECTED[*]}"
  for status in installed install update configure skipped unsupported manual note; do
    case $status in installed) label='Already installed';; install) label='Will install';; update) label='Will update';; configure) label='Will configure';; skipped) label='Skipped';; unsupported) label='Unsupported';; manual) label='Manual intervention';; note) label='Notes';; esac
    count=0
    for i in "${!ACTION_STATUS[@]}"; do [[ ${ACTION_STATUS[i]} != "$status" ]] || ((count+=1)); done
    (( count > 0 )) || continue
    ui_section "$status" "$label" "$count"
    for i in "${!ACTION_STATUS[@]}"; do
      [[ ${ACTION_STATUS[i]} == "$status" ]] || continue
      printf '  - '; ui_style "$status" "${ACTION_TITLE[i]}"
      [[ -z ${ACTION_NOTE[i]} ]] || printf ' — %s' "${ACTION_NOTE[i]}"
      printf '\n'
      if [[ $status == install || $status == configure ]]; then
        printf '      operation: '; describe_action "${ACTION_TYPE[i]}" "${ACTION_ARG[i]}"; printf '\n'
      fi
    done
  done
  printf '\nPrivilege/restart: APT and repository actions request sudo; no action reboots the system. Shell/group changes may require a new login session.\n'
}
