#!/usr/bin/env bash
plan_local_llms() {
  plan_apt 'Vulkan diagnostics' vulkan-tools vulkaninfo
  plan_apt 'Mesa Vulkan drivers' mesa-vulkan-drivers ''
  if has_command ollama; then add_action installed Ollama none ollama - 'Inspect ollama ps after loading a model to see processor'
  else plan_manual Ollama 'Official Linux installer must be inspected before execution; https://ollama.com/download/linux. Do not assume a Vulkan backend'; fi
  if has_command llama-cli || [[ -x $HOME/.local/bin/llama-cli ]]; then
    add_action installed llama.cpp none '' - 'Existing installation retained'
  else
    plan_manual 'llama.cpp with Vulkan' 'Install build-essential cmake ninja-build libvulkan-dev glslc spirv-headers; clone https://github.com/ggml-org/llama.cpp at a reviewed tag, then cmake -B build -DGGML_VULKAN=ON and cmake --build build'
  fi
  if has_command lspci; then add_action installed 'GPU diagnostic' none '' - 'Run lspci -nnk | grep -A3 VGA'
  else plan_apt 'GPU diagnostic' pciutils lspci; fi
  plan_manual 'GPU backend verification' 'Run vulkaninfo --summary, then a model-specific inference and inspect device/backend output; no models are downloaded automatically'
}
