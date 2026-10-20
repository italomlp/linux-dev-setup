# Linux Dev Setup

Modular Bash installer for an x86_64 desktop running Ubuntu, Debian, Linux Mint, Pop!_OS, or Zorin OS. Preview the plan, choose modules, then approve changes. Run as your normal user; the installer requests `sudo` when needed.

[Português (Brasil)](README.pt-BR.md) · [Installation decisions and side effects](docs/tooling.md)

## Run from a release (no Git required)

You need Bash, curl, tar, Python 3, and `sha256sum`. Download, verify, and extract version **0.2.1**:

```bash
curl -fLO https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.1/linux-dev-setup-v0.2.1.tar.gz
curl -fLO https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.1/linux-dev-setup-v0.2.1.tar.gz.sha256
sha256sum -c linux-dev-setup-v0.2.1.tar.gz.sha256 && \
  tar -xzf linux-dev-setup-v0.2.1.tar.gz && \
  cd linux-dev-setup-v0.2.1 && \
  ./install.sh --interactive --dry-run && \
  ./install.sh --interactive
```

Continue only if the checksum reports `OK`. The checksum detects corruption; it is downloaded from the same release and is not an independent signature.

Alternatively, download the small launcher, inspect it, and run it. It downloads and verifies the matching release automatically:

```bash
curl -fL https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.1/install.sh -o linux-dev-setup-launcher.sh
less linux-dev-setup-launcher.sh
bash linux-dev-setup-launcher.sh --interactive --dry-run
bash linux-dev-setup-launcher.sh --interactive
```

For a one-line installation, run the release launcher directly:

```bash
curl -fsSL https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.1/install.sh | bash
```

This opens the module menu, verifies the release archive, and asks for approval before applying changes. To preview only, replace `bash` with `bash -s -- --interactive --dry-run`.

## Run from source (no release download)

```bash
git clone https://github.com/italomlp/linux-dev-setup.git
cd linux-dev-setup
./install.sh --interactive --dry-run
./install.sh --interactive
```

To use the exact release source, run `git checkout v0.2.1` before starting the installer. The default branch can contain newer changes.

## Choose what to install

```bash
./install.sh --list                                  # List module names
./install.sh                                         # Preview all modules; changes nothing
./install.sh --module terminal,ai-agents --dry-run     # Preview selected modules
./install.sh --module terminal,ai-agents               # Run selected modules
./install.sh --all --dry-run                          # Preview everything
./install.sh --all                                    # Run everything
./install.sh --checklist                              # Complete logins and other follow-ups
./install.sh --checklist --dry-run                    # Read-only follow-up status
./diagnose.sh                                         # Read-only GPU, KVM and Docker diagnostics
```

`--interactive` selects modules by number. `0` selects all; `q` exits. Docker Desktop and Flatpak/Zen have additional menu choices. Existing tools are generally retained; AI CLI migration and repository repairs are deliberate exceptions.

Never run `sudo ./install.sh`. Review every plan before executing it. `--yes` skips the initial yes/no question, **but cannot bypass the explicit `apply` confirmation for changes**. Runs without a controlling terminal cannot apply changes. Android terms/licenses and tool authentication remain interactive.

### Modules

| Module | Installs or configures |
|---|---|
| `system` | Git, Git LFS, GitHub CLI, Lazygit; curl, wget, zip/unzip, build-essential, jq, ripgrep, fd, fzf, bat, eza, htop, btop, tree, OpenSSH client, rsync, Vim. |
| `terminal` | Zsh, GNU Stow, Zellij, Starship, Zsh autosuggestions/syntax highlighting, Warp; Ghostty on supported Ubuntu 26.04. Manages Zsh configuration and offers changing the login shell. |
| `javascript` | mise, Node LTS, pnpm and Bun. Activates mise in Bash. TypeScript remains a project dependency. |
| `docker` | Docker Desktop when the base OS and KVM support it; KVM modules/group access if needed. Engine, CLI, containerd, Compose and Buildx are an explicit fallback only. |
| `editors` | Vim and official Visual Studio Code; two-step checklist for account review and Google Antigravity extension installation, with login instructions through `agy`. |
| `ai-agents` | Standalone Claude Code, Codex and OpenCode; Gemini CLI in a stable npm prefix using active Node 20+. Antigravity CLI, Claude Desktop and ChatGPT Desktop where supported. Migrates old mise npm CLI copies. |
| `local-llms` | Ollama and its systemd service, llama.cpp with Vulkan where supported; Vulkan tools, Mesa Vulkan drivers, pciutils, zstd as needed. Downloads no models. |
| `android` | Existing JDK or OpenJDK 17; Android Studio, Command-line Tools, Platform Tools, newest stable Android platform/Build Tools, SDK environment and KVM setup. SDK licenses require approval. |
| `applications` | Flatpak/Flathub and Zen; Vivaldi, Chrome, Tailscale, DBeaver, Bruno, Slack. Retains validated vendor repositories and cleans up redundant script-owned browser sources. |
| `productivity` | GNOME Tweaks and Extension Manager on GNOME; KDE Connect and Restic. Snapshot layout, backup destination and retention remain manual. |

Availability depends on OS, repositories, architecture and existing installations. Unsupported choices appear as manual steps rather than being silently substituted.

### Settings

Edit `config/settings.conf` or set variables for one invocation:

```bash
INSTALL_DOCKER_DESKTOP=0 INSTALL_FLATPAK=0 ./install.sh --all --dry-run
INSTALL_DOCKER_ENGINE_FALLBACK=1 ./install.sh --module docker --dry-run
```

Defaults: Docker Desktop and Flatpak enabled; Docker Engine fallback disabled. Engine fallback checks for conflicting container packages and does not remove them automatically. Essential packages are listed in `config/packages.conf`.

## Repairs, installation methods, and updates

- APT is preferred for system packages. Official signed repositories are added where required; no Snap is used. APT refuses transactions that remove existing packages.
- Development runtimes stay in mise, allowing project-specific versions. Claude/Codex/OpenCode use official standalone installers; their commands are exposed in `~/.local/bin`.
- Gemini uses `npm install --global --prefix "$HOME/.local/share/linux-dev-setup/npm" @google/gemini-cli`. Its stable launcher uses whichever Node is active. No extra Node is installed by the AI module and npm's global configuration is unchanged. Select Node 20+ before running Gemini.
- Rerunning `terminal,ai-agents` repairs Warp sources and migrates version-specific CLI copies. Old AI npm packages are removed from existing mise Node prefixes only after replacement verification. Authentication/settings are retained. Open a new terminal afterward.
- Official downloads use published digests/signatures when available. ChatGPT Desktop and VS Code use HTTPS and package validation without an independent published checksum. Native CLI installers handle their own downloads. See [methods, trust boundaries and effects](docs/tooling.md).

To update: use APT normally, `flatpak update --user`, or `mise upgrade` as appropriate. Claude uses its native updater; repeat the official Codex installer for Codex; use `opencode upgrade` for OpenCode. For Gemini, repeat the npm command with the explicit prefix above. A rerun verifies existing installations and installs missing tools; it is not a general upgrade command.

## Changes that need your approval

Before execution, the installer lists changing actions and requires you to type **`apply` in a terminal**. This includes package/repository changes, replacement of managed shell configuration or binaries, removal of legacy AI packages, and the OS changes below. Declining cancels before planned actions run. `--yes` does not grant this approval.

| Effect | Protection / recovery |
|---|---|
| Add APT sources, keys and packages; package scripts may start services or change dependencies. | Plan and explicit approval; `--no-remove` rejects package removals. Package installation itself is not automatically rolled back. |
| Remove redundant installer-owned Warp, Claude Desktop, Chrome or Vivaldi APT sources. | Retain the vendor source; require the corresponding vendor checks; source backups in `~/.local/state/linux-dev-setup/repo-backups/`. Warp repair also runs after Warp installation. |
| Replace managed blocks in `.bashrc`, `.zshrc`, `.profile`; replace user commands/symlinks. | Existing shell files receive adjacent `.backup.TIMESTAMP` copies. Configuration outside managed blocks is retained. User binaries are not all backed up. |
| Uninstall the four old AI npm packages from mise Node prefixes. | Verify replacements first; preserve credentials/settings and unrelated npm packages. No Node versions are deleted. |
| Load KVM modules; add your user to `kvm`; change the login shell with `chsh`. | Explicit approval; shell change may require a password. Group/shell changes may need a new login. No automatic `docker` group membership. |
| Install Ollama files under `/usr`, create its service account, grant render/video access, enable/start `ollama.service`. | Explicit approval. Existing service definition is retained; existing Ollama commands normally skip installation. To stop the installed service later: `sudo systemctl disable --now ollama`. |

No partition formatting, bootloader changes, automatic reboots, container/volume deletion or snapshot-layout changes are planned. The installer also does not configure backups or download LLM models. Vendor installers and package maintainer scripts remain an external trust boundary; review the plan and sources before approval.

## After running

Use `./install.sh --checklist` for logins and license follow-ups. Checklist confirmations for tools without a reliable probe are stored in `~/.local/state/linux-dev-setup/checklist.done`, without credentials. Start Docker Desktop and accept its terms before selecting its `desktop-linux` context; it has separate containers/images/volumes from Engine's `default` context.

Logs are stored with mode `0600` in `~/.local/state/linux-dev-setup/`. A failed action skips its dependents; independent actions can continue. Fix the reported cause and rerun the relevant module. There is no full-system rollback. Local dry-run creates no persistent installation state and makes no network requests; the release launcher must download the release before its dry-run.

## Test and build a release

```bash
bash tests/run.sh
bash scripts/package.sh --repo italomlp/linux-dev-setup
```

Tests use temporary fixtures and mocked installation commands. The build reads `VERSION` and writes the archive, checksum, and launcher to `dist/`. The GitHub workflow tests pushes and publishes those three assets when a `vVERSION` tag is pushed. Version 0.2.1 uses tag `v0.2.1`.

For VS Code, `./install.sh --module editors` installs Microsoft's official package. Then use `./install.sh --checklist`: review/sign in to your VS Code account (Settings Sync is optional), install the Google Antigravity extension, then follow step 2’s instructions to sign in through `agy` and run **Developer: Reload Window** in VS Code. Later steps stay blocked until their prerequisites are complete. Only `agy` and the VS Code extension are supported; standalone Antigravity IDE/app installation has been removed. See [installation sources and setup details](docs/tooling.md#vs-code-and-antigravity-setup).
