#!/usr/bin/env bash
set -Eeuo pipefail
printf 'GPU:\n'
if command -v lspci >/dev/null 2>&1; then
  lspci -nnk | grep -Ei -A3 'VGA|Display|3D controller' || true
else printf '  lspci unavailable (install pciutils)\n'; fi
found_vram=0
for file in /sys/class/drm/card*/device/mem_info_vram_total; do
  [[ -r $file ]] || continue
  bytes=$(cat "$file")
  printf '  VRAM %s: %s MiB\n' "$file" "$((bytes / 1024 / 1024))"
  found_vram=1
done
if (( ! found_vram )); then printf '  VRAM sysfs data unavailable\n'; fi
printf '\nVulkan:\n'
if command -v vulkaninfo >/dev/null 2>&1; then vulkaninfo --summary 2>&1 || true
else printf '  vulkaninfo unavailable (install vulkan-tools)\n'; fi
printf '\nKVM:\n'
if [[ -e /dev/kvm ]]; then
  ls -l /dev/kvm
  [[ -r /dev/kvm && -w /dev/kvm ]] && printf '  Current user can access KVM\n' || printf '  Current user lacks KVM read/write access\n'
else printf '  /dev/kvm unavailable\n'; fi
printf '\nInference:\n'
if command -v ollama >/dev/null 2>&1; then ollama ps 2>&1 || true
else printf '  Ollama unavailable\n'; fi
if command -v llama-cli >/dev/null 2>&1; then llama-cli --list-devices 2>&1 || true
else printf '  llama-cli unavailable\n'; fi
printf '\nDocker contexts:\n'
if command -v docker >/dev/null 2>&1; then docker context ls 2>&1 || true
else printf '  Docker unavailable\n'; fi
