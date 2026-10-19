#!/usr/bin/env bash
# AI command locations are independent of version-manager installation prefixes.
ai_cli_path() { printf '%s/.local/bin/%s' "$HOME" "$1"; }
ai_cli_ready() {
  local path mise_node_root
  path=$(ai_cli_path "$1")
  [[ -x $path ]] || return 1
  mise_node_root=$(readlink -m "${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/node")
  case $(readlink -f "$path") in "$mise_node_root"/*) return 1;; esac
  "$path" --version >/dev/null 2>&1
}
ai_cli_legacy_prefixes() {
  local prefix resolved
  for prefix in "${MISE_DATA_DIR:-$HOME/.local/share/mise}"/installs/node/*; do
    [[ -d $prefix/lib/node_modules/$1 ]] || continue
    resolved=$(readlink -f "$prefix")
    printf '%s\n' "$resolved"
  done | sort -u
}
ai_cli_cleanup() {
  local package=$1 prefix
  while IFS= read -r prefix; do
    [[ -n $prefix ]] || continue
    [[ -x $prefix/bin/node && -f $prefix/lib/node_modules/npm/bin/npm-cli.js ]] || {
      echo "Cannot remove legacy $package from $prefix: npm missing" >&2; return 1;
    }
    PATH="$prefix/bin:$PATH" "$prefix/bin/node" "$prefix/lib/node_modules/npm/bin/npm-cli.js" uninstall --global --prefix "$prefix" "$package" || return 1
  done < <(ai_cli_legacy_prefixes "$package")
}
install_ai_cli() (
  set -Eeuo pipefail
  local binary=$1 package tmp url
  case $binary in
    claude) package=@anthropic-ai/claude-code; url=https://claude.ai/install.sh;;
    codex) package=@openai/codex; url=https://chatgpt.com/codex/install.sh;;
    opencode) package=@opencode/cli; url=https://opencode.ai/v2/install;;
    gemini) package=@google/gemini-cli; url='';;
    *) return 1;;
  esac
  mkdir -p "$HOME/.local/bin" || return 1
  if ! ai_cli_ready "$binary"; then
    tmp=$(mktemp -d) || return 1; trap 'rm -rf "$tmp"' EXIT
    if [[ $binary == gemini ]]; then
      if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
        echo 'Gemini requires an active Node/npm; no runtime will be installed' >&2; return 1
      fi
      node -e 'if (+process.versions.node.split(".")[0] < 20) process.exit(1)' || { echo 'Gemini requires active Node 20 or newer' >&2; return 1; }
      npm install --global --prefix "$HOME/.local/share/linux-dev-setup/npm" "$package" || return 1
      cat > "$tmp/gemini" <<'LAUNCHER'
#!/usr/bin/env bash
command -v node >/dev/null || { echo 'Gemini requires an active Node 20 or newer' >&2; exit 1; }
node -e 'if (+process.versions.node.split(".")[0] < 20) process.exit(1)' || { echo 'Gemini requires an active Node 20 or newer' >&2; exit 1; }
exec node "$HOME/.local/share/linux-dev-setup/npm/bin/gemini" "$@"
LAUNCHER
      chmod 755 "$tmp/gemini" || return 1
      "$tmp/gemini" --version || return 1
      mv -f "$tmp/gemini" "$(ai_cli_path gemini)" || return 1
    else
      curl -fsSL --retry 3 "$url" -o "$tmp/install.sh" || return 1
      # Keep the vendor's validation and bundled runtime behavior.
      if [[ $binary == codex ]]; then CODEX_INSTALL_DIR="$HOME/.local/bin" sh "$tmp/install.sh" || return 1
      elif [[ $binary == opencode ]]; then bash "$tmp/install.sh" --no-modify-path || return 1
      else bash "$tmp/install.sh" || return 1; fi
      if [[ $binary == opencode && -x $HOME/.opencode/bin/opencode ]]; then
        ln -sfn "$HOME/.opencode/bin/opencode" "$(ai_cli_path opencode)" || return 1
      fi
    fi
    ai_cli_ready "$binary" || { echo "Standalone $binary installation could not be verified; retaining legacy installation" >&2; return 1; }
  fi
  ai_cli_cleanup "$package"
)
configure_ai_path() {
  local file tmp
  mkdir -p "$HOME/.local/bin" || return 1
  for file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    tmp=$(mktemp) || return 1
    if [[ -f $file ]]; then
      cp -p "$file" "$file.backup.$(date +%Y%m%d-%H%M%S)" || return 1
      awk '/^# linux-dev-setup AI PATH$/{skip=1;next} /^# end linux-dev-setup AI PATH$/{skip=0;next} !skip{print}' "$file" > "$tmp"
    fi
    cat >> "$tmp" <<'BLOCK'

# linux-dev-setup AI PATH
_linux_dev_setup_ai_path() {
  case $PATH in "$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
}
_linux_dev_setup_ai_path
if [ -n "${ZSH_VERSION:-}" ]; then
  typeset -ga precmd_functions
  precmd_functions=(${precmd_functions:#_linux_dev_setup_ai_path} _linux_dev_setup_ai_path)
elif [ -n "${BASH_VERSION:-}" ]; then
  if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == 'declare -a '* ]]; then
    [[ " ${PROMPT_COMMAND[*]} " == *' _linux_dev_setup_ai_path '* ]] || PROMPT_COMMAND+=(_linux_dev_setup_ai_path)
  else
    case ";${PROMPT_COMMAND:-};" in *';_linux_dev_setup_ai_path;'*) ;; *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_linux_dev_setup_ai_path";; esac
  fi
fi
# end linux-dev-setup AI PATH
BLOCK
    cat "$tmp" > "$file" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  done
  export PATH="$HOME/.local/bin:$PATH"
}
