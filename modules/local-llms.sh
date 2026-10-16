#!/usr/bin/env bash
plan_local_llms() {
  plan_apt 'Vulkan diagnostics' vulkan-tools vulkaninfo
  plan_apt 'Mesa Vulkan drivers' mesa-vulkan-drivers ''
  if has_command ollama; then add_action installed Ollama none ollama - 'Inspect ollama ps after loading a model to see processor'
  else
    plan_apt zstd zstd zstd
    local zstd_dep=-
    [[ ${ACTION_STATUS[-1]} != install ]] || zstd_dep=$((${#ACTION_TYPE[@]}-1))
    add_action install Ollama ollama-release '' "$zstd_dep" 'download verified Ollama release from GitHub; install official Linux archive and systemd service'
  fi
  if has_command llama-cli || [[ -x $HOME/.local/bin/llama-cli ]]; then
    add_action installed llama.cpp none '' - 'Existing installation retained'
  elif [[ $(ubuntu_compat_version) == 24.04 || $(ubuntu_compat_version) == 26.04 ]]; then
    add_action install 'llama.cpp with Vulkan' llama-vulkan '' - 'download verified llama.cpp Vulkan release from GitHub; install user binaries and libraries'
  else
    plan_manual 'llama.cpp with Vulkan' 'Install build-essential cmake ninja-build libvulkan-dev glslc spirv-headers; clone https://github.com/ggml-org/llama.cpp at a reviewed tag, then cmake -B build -DGGML_VULKAN=ON and cmake --build build'
  fi
  if has_command lspci; then add_action installed 'GPU diagnostic' none '' - 'Run lspci -nnk | grep -A3 VGA'
  else plan_apt 'GPU diagnostic' pciutils lspci; fi
  add_action configure 'GPU backend check' gpu-check '' - 'Run vulkaninfo --summary and llama-cli --list-devices after installation'
  plan_manual 'Model-specific GPU verification' 'Choose a model to test inference and inspect processor/backend output; no models are downloaded automatically'
}
