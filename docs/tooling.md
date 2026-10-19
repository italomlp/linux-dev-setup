# Installation decisions and system effects

[Português (Brasil)](tooling.pt-BR.md) · [Run instructions](../README.md)

The installer plans before executing. It normally retains existing tools, uses distribution packages where practical, and leaves unsupported cases as manual steps. Runtime downloads resolve vendor metadata during execution; local dry-run does not access the network. This is not an OS provisioning or rollback system.

## Sources and methods

| Tools | Method and reason |
|---|---|
| Essential CLI packages, Vim, OpenJDK 17, desktop utilities | Distribution APT packages. Missing candidates become manual steps. Debian names `fdfind` and `batcat` receive Zsh aliases. |
| GitHub CLI | Official signed [APT repository](https://github.com/cli/cli/blob/trunk/docs/install_linux.md); checks published signing-key fingerprints. |
| Lazygit, Starship, Zellij | APT when available; otherwise official GitHub release archive verified against the GitHub asset SHA-256 digest. Installs fallback binaries in `~/.local/bin`. |
| Warp | Official signed [APT repository](https://docs.warp.dev/getting-started/quickstart/installation-and-setup). Reuses vendor source; validates its URI/suite/type/key path before backing up/removing only the redundant script source. Checks again after package installation. |
| Ghostty | [Official Ubuntu package](https://ghostty.org/docs/install/binary) on Ubuntu 26.04 when available; manual elsewhere. No unapproved community repository. |
| Zsh, Stow, autosuggestions, syntax highlighting | Distribution APT. Verifies plugin scripts before editing `.zshrc`; loads syntax highlighting last. |
| mise | APT through extrepo's official mise entry. See [mise installation](https://mise.jdx.dev/installing-mise.html). |
| Node LTS, pnpm, Bun | mise global defaults; projects can pin other versions. No APT Node or NVM installation. TypeScript is a project dependency. |
| Docker Desktop | Official `.deb` and matching SHA-256 resolved from [Docker release notes](https://docs.docker.com/desktop/release-notes/); official signed Docker APT source. Requires compatible Ubuntu base/KVM. Desktop terms are accepted by the user after launch. |
| Docker Engine/CLI, containerd, Compose, Buildx | Explicit fallback through Docker's signed APT repository, only when preconditions and conflict checks pass. Mint uses its Ubuntu base (for example `noble`), not Mint's own codename. Existing engines are retained. |
| Claude Code | Official [native installer](https://support.claude.com/en/articles/14554922-claude-code-user-faq), `https://claude.ai/install.sh`. Stable command `~/.local/bin/claude`; no project Node dependency. |
| Codex CLI | Official [standalone installer](https://learn.chatgpt.com/docs/codex/cli), `https://chatgpt.com/codex/install.sh`. Forces `CODEX_INSTALL_DIR=~/.local/bin` for a stable command. |
| OpenCode | Official [standalone installer](https://dev.opencode.ai/v2/docs), `https://opencode.ai/v2/install`, with `--no-modify-path`. Links its `~/.opencode/bin/opencode` into `~/.local/bin`. |
| Gemini CLI | Official [npm package](https://geminicli.com/docs/get-started/installation/), explicit prefix `~/.local/share/linux-dev-setup/npm`. Stable launcher calls the active Node and requires Node 20+. No new runtime or persistent npm-prefix setting. |
| Antigravity IDE / CLI | Official HTTPS tarball; CLI verifies vendor SHA-512 manifest. IDE has no checksum published by the download page. See [vendor downloads](https://antigravity.google/download). |
| Claude Desktop | Official signed APT source, published fingerprint verified. Supported Ubuntu/Debian versions are checked; Ubuntu derivatives use detected base compatibility without claiming vendor support. See [vendor guidance](https://support.claude.com/en/articles/10065433-install-claude-desktop). |
| ChatGPT Desktop | Official HTTPS `.deb`, validated package name/architecture. No checksum published on the download page. Base-version compatibility checks apply. See [Linux app](https://learn.chatgpt.com/docs/linux/linux-app). |
| Ollama | Official GitHub Linux release, GitHub asset SHA-256 verified; installs under `/usr` and enables a systemd service. No models or separate ROCm package downloaded. See [Linux installation](https://docs.ollama.com/linux). |
| llama.cpp | Official Ubuntu Vulkan GitHub release, asset SHA-256 verified. User installation with a versioned directory, `current` symlink and launcher. Manual build on unsupported bases. |
| Vulkan tools, Mesa Vulkan drivers, pciutils | Distribution APT for diagnostics and Vulkan support; no replacement of the kernel GPU driver or proprietary-driver installation. |
| Android Studio | Official Google Linux tarball with published SHA-256, extracted under `~/.local/share`. Starts the Setup Wizard. Optional `ANDROID_STUDIO_TARBALL`/`ANDROID_STUDIO_SHA256` select an existing archive. |
| Android SDK tools/platforms | Official Google Command-line Tools ZIP with published SHA-256. Reuses the selected SDK; conflicting SDK roots require manual resolution. `sdkmanager` installs Platform Tools and newest stable platform/Build Tools after interactive terms/licenses. ADB is not installed through APT. |
| Zen | Official Flathub application `app.zen_browser.zen`, user installation. No system default browser change. |
| Chrome, Vivaldi | Official signed APT sources. Validates vendor source/key and package policy before backing up/removing redundant script-owned sources. |
| Tailscale | Official signed stable APT source for the detected Ubuntu base. Login remains manual. |
| Slack | Official `.deb` with vendor debsig key/policy and `debsig-verify`, then APT installation. |
| DBeaver, Bruno | Vendor APT sources and keyrings. DBeaver key is checked for GPG parseability; Bruno checks its published short key ID. These checks are weaker than full fingerprint pinning. Bruno's repository uses its vendor HTTP endpoint with signed APT metadata. |
| GNOME utilities, KDE Connect, Restic | Distribution APT; GNOME utilities only on GNOME. Backup destinations, retention and Timeshift/Snapper setup are manual. |

## Trust and compatibility

- Downloaded standalone installer scripts execute as your user and implement their vendors' download/verification logic. The project does not independently pin every payload they fetch. APT package maintainer scripts can run as root.
- APT repositories use dedicated keys. Validation differs by vendor as described above; repository duplication checks do not independently authenticate a new key fingerprint.
- Distribution recognition is not a guarantee of upstream support. Mint, Pop!_OS and Zorin use their Ubuntu base where the planner supports it. The installer currently accepts only x86_64.
- Docker Desktop and Engine have separate contexts/data. The script does not stop existing container daemons, delete containers/volumes, or automatically grant root-equivalent `docker` group access.
- No inference model is downloaded. Confirm GPU use separately with a chosen model, `ollama ps`, `vulkaninfo --summary`, and `llama-cli --list-devices`.

## Destructive/replacing actions and confirmation

Every planned changing action requires explicit terminal approval (`apply`) before execution, including with `--yes`. Without a controlling terminal, the installer stops before changes. The approval lists actual actions and discloses their effects. Android license prompts remain separate. The checklist may launch tools and persist manual completion markers at the user's request.

- **System packages and repositories:** adds sources/keys and installs packages; maintainer scripts may start services or alter dependencies. All APT installation commands use `--no-remove`, so any transaction requiring installed-package removal fails instead. There is no automatic rollback of package installs.
- **Repository cleanup:** backs up then removes only redundant script-owned lists for Warp, Claude Desktop, Chrome and Vivaldi when the corresponding vendor-source checks pass. Backups: `~/.local/state/linux-dev-setup/repo-backups/`. Restoring a backup without resolving duplicate signing-key settings can break APT again.
- **Shell/user commands:** replaces managed blocks in `.bashrc`, `.zshrc` and `.profile` with adjacent timestamped backups of existing shell files. Other content is retained. Installs/replaces user binaries, launchers and symlinks; those binaries are not all backed up.
- **AI migration:** verifies each replacement before uninstalling only its matching npm package in existing mise Node prefixes. Does not delete Node versions or tool credentials/configuration. An uninstall failure is reported and can be retried.
- **KVM and login:** may load `kvm` plus the CPU-specific module, add the current user to `kvm`, and change the login shell with `chsh`. New login/password may be needed. No firmware change is automated.
- **Ollama service:** extracts vendor files into `/usr`, creates account/home `/usr/share/ollama` if absent, grants render/video groups, installs a unit only when no unit exists, reloads systemd and runs `systemctl enable --now ollama`. Stop/disable with `sudo systemctl disable --now ollama`; uninstall files manually only after checking ownership and retaining desired data.
- **User archives and SDK:** installs application trees under `~/.local/share` and SDK packages in the selected SDK; these consume disk space and can replace/update tool files. Licenses are interactive. No SDK root is deleted.

No partition formatting, bootloader changes, automatic reboot, snapshot-layout changes or model/container-data deletion is planned. Do not treat that as a sandbox for vendor installers: review upstream sources before approval.

## Optional pre-downloaded packages

`DOCKER_DESKTOP_DEB` plus `DOCKER_DESKTOP_SHA256`, and `ANDROID_STUDIO_TARBALL` plus `ANDROID_STUDIO_SHA256`, allow verified local archives. `LAZYGIT_ARCHIVE`/`LAZYGIT_SHA256`, `STARSHIP_ARCHIVE`/`STARSHIP_SHA256` and `ZELLIJ_ARCHIVE`/`ZELLIJ_SHA256` similarly select fallback archives. Supply both path and the matching official digest, then inspect `--dry-run`.
