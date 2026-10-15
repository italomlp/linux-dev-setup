# Fontes e métodos de instalação

Pesquisa em 15 de outubro de 2026. A lista diferencia ações automatizadas de etapas manuais que exigem versão, checksum, aceite ou validação local. Não se usam Snap nem drivers proprietários por conveniência; nenhum aplicativo é instalado por dois gestores.

| Ferramentas | Método | Motivo e fonte |
|---|---|---|
| Git, Git LFS, curl, wget, unzip, zip, build-essential, jq, ripgrep, fd-find, fzf, bat, eza, htop, btop, tree, OpenSSH Client, rsync, Vim | APT da distribuição | Binários de sistema com atualizações integradas; `fdfind` e `batcat` recebem aliases Zsh. Ausência de candidato vira etapa manual. |
| GitHub CLI | Repositório APT oficial com chave em keyring dedicado | Atualizações pelo APT; a chave é comparada a fingerprints publicados em [GitHub CLI Linux install](https://github.com/cli/cli/blob/trunk/docs/install_linux.md). |
| Lazygit | APT se houver candidato; caso contrário, release oficial manual | Mantém integração com APT quando disponível. [Releases](https://github.com/jesseduffield/lazygit/releases). |
| Warp | Repositório APT oficial assinado | Principal terminal; sem sandbox para acesso pleno a Git, SSH e CLI. [Instalação Warp](https://docs.warp.dev/getting-started/quickstart/installation-and-setup). |
| Ghostty | APT oficial do Ubuntu 26.04; manual nos demais | Evita pacote comunitário sem escolha explícita. [Instalação Ghostty](https://ghostty.org/docs/install/binary). |
| Zsh, Stow, Starship, Zellij, autosuggestions, syntax highlighting | APT da distribuição | Integração de shell com custo baixo; candidatos ausentes são manuais. |
| mise | `extrepo` + APT | Fonte documentada para Debian 11+/Ubuntu 22.04+; mantém atualizações no APT. [Instalação mise](https://mise.jdx.dev/installing-mise.html). |
| Node LTS, pnpm, Bun | mise | Node nunca é instalado via APT/NVM. Projetos podem definir versões próprias. [Node no mise](https://mise.jdx.dev/lang/node.html). |
| TypeScript | Dependência de projeto | Evita versão global que diverge do projeto. |
| Docker Engine, CLI, Compose, Buildx | Repositório estável Docker APT; somente Ubuntu 22.04/24.04/26.04 e Debian 12/13 | Evita misturar pacotes `docker.io`/`containerd` com pacotes oficiais. [Ubuntu](https://docs.docker.com/engine/install/ubuntu/), [Debian](https://docs.docker.com/engine/install/debian/). |
| Docker Desktop | Manual, .deb oficial e checksum | Requer KVM e aceite de termos; daemon/contexto/armazenamento próprios. [Docker Desktop Linux](https://docs.docker.com/desktop/setup/install/linux/). |
| Antigravity IDE e CLI | Manual, pacote/instalador oficial | Página e artefatos mudam; preservar autenticação e validar download. [IDE](https://codelabs.developers.google.com/getting-started-agy-ide), [CLI](https://codelabs.developers.google.com/antigravity-cli-hands-on). |
| Claude Code, Codex CLI, OpenCode, Gemini CLI | npm global sob mise | CLIs oficiais, sem `sudo npm` ou login automático. [Claude](https://docs.anthropic.com/en/docs/claude-code/getting-started), [Codex](https://help.openai.com/en/articles/11096431), [OpenCode](https://dev.opencode.ai/v2/docs), [Gemini](https://geminicli.com/docs/get-started/installation/). |
| Claude Desktop | Repositório APT oficial em Ubuntu 22.04+/Debian 12+; manual em derivados | Beta oficial com fingerprint verificado. [Claude Desktop Linux](https://support.claude.com/en/articles/10065433-install-claude-desktop). |
| ChatGPT Desktop | Manual, .deb oficial em Ubuntu 24.04/26.04 e Debian 13 | Prévia oficial; pacote configura repositório de atualização. Sem wrappers/PWAs. [ChatGPT Linux](https://learn.chatgpt.com/docs/linux/linux-app). |
| Ollama | Manual, instalador oficial | Inspeção do instalador e backend necessária; nenhum ROCm/modelo automático. [Download](https://ollama.com/download/linux), [GPU](https://docs.ollama.com/gpu). |
| llama.cpp | Manual, fonte oficial compilada com Vulkan | Tag e build dependem do SDK/Vulkan local. [Build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md). |
| Vulkan tools, Mesa Vulkan drivers, pciutils | APT | Diagnóstico sem substituir o driver AMDGPU. |
| Android Studio, SDK, Platform Tools | Manual, download e assistente oficiais | Licenças e componentes de SDK são interativos; evita SDK duplicado. [Studio](https://developer.android.com/studio/install), [SDK Manager](https://developer.android.com/tools/sdkmanager). |
| JDK 17, ADB | APT, se apropriado | React Native recomenda JDK 17; JDK existente de outra versão vira revisão manual. [React Native](https://reactnative.dev/docs/set-up-your-environment). |
| Zen Browser | Flatpak oficial no Flathub | Método recomendado pelo Zen, isolamento de navegador; limita integração nativa específica. [Zen Linux](https://docs.zen-browser.app/guides/install-linux). |
| Vivaldi, Chrome | Manual, .deb oficial | Integração de navegador e atualização do fornecedor; não se altera o padrão. [Vivaldi](https://help.vivaldi.com/desktop/install-update/install-the-vivaldi-browser/), [Chrome](https://support.google.com/chrome/a/answer/9025926). |
| Tailscale | Manual, repositório estável da distribuição | Método depende da versão base; login é pessoal. [Linux](https://tailscale.com/docs/install/linux). |
| GNOME Tweaks, Extension Manager, KDE Connect, Restic | APT | Utilitários GNOME só no GNOME; backup precisa destino explícito. |
| Timeshift ou Snapper | Manual | Exige verificar layout Btrfs antes de configurar snapshots. |

**Compatibilidade:** Pop!_OS, Zorin e Mint são detectados como distribuições próprias, com `UBUNTU_CODENAME` para diagnóstico. O repositório Docker só é configurado automaticamente em Ubuntu/Debian oficialmente suportados. Para derivações, siga documentação da distribuição e revise conflitos antes de qualquer mudança de daemon.
