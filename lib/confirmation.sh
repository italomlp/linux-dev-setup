#!/usr/bin/env bash
read_change_approval() {
  local answer
  IFS= read -r answer || return 1
  [[ $answer == apply ]]
}
confirm_planned_changes() {
  local i changes=0
  for i in "${!ACTION_TYPE[@]}"; do
    [[ ${ACTION_STATUS[i]} == install || ${ACTION_STATUS[i]} == configure ]] || continue
    [[ ${ACTION_TYPE[i]} != gpu-check ]] || continue
    ((changes+=1))
  done
  (( changes > 0 )) || return 0
  printf '\nChanges requiring explicit approval (%s):\n' "$changes"
  for i in "${!ACTION_TYPE[@]}"; do
    [[ ${ACTION_STATUS[i]} == install || ${ACTION_STATUS[i]} == configure ]] || continue
    [[ ${ACTION_TYPE[i]} != gpu-check ]] || continue
    printf '  - %s: %s\n' "${ACTION_TITLE[i]}" "${ACTION_NOTE[i]:-}"
  done
  cat <<'NOTICE'
Depending on the actions listed above, this can:
  * Install system packages and signing keys, change APT sources, and run vendor/package scripts.
    APT will refuse transactions that remove installed packages. Packages may start services.
  * Back up/remove redundant installer-owned APT sources (including after Warp installation).
  * Replace managed shell/profile blocks and user executables; back up existing shell files.
  * Remove legacy AI npm packages only after verifying their replacements; retain credentials.
  * Install VS Code through Microsoft's package, including its desktop/login handlers and
    package-managed signed APT repository for updates. Extension/account setup is in --checklist.
  * Change the login shell; load KVM modules or add the current user to the kvm group.
  * Install Ollama under /usr, create its service account/groups, and enable/start its service.
Only the planned actions run. No partitions, bootloader, or model data are intentionally removed.
--yes does not bypass this approval. Refusing leaves the system unchanged.
NOTICE
  if ! { : </dev/tty; } 2>/dev/null; then
    echo 'Changes require interactive confirmation; rerun from a terminal without piping answers.' >&2
    return 1
  fi
  printf 'Type apply to approve the listed changes, or anything else to cancel: ' >/dev/tty
  read_change_approval </dev/tty || { echo 'Cancelled before changes.' >&2; return 1; }
}
