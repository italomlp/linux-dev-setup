# Fontes e métodos de instalação

Métodos revisados em 19 de outubro de 2026. Downloads e checksums publicados pelos fornecedores são resolvidos durante a execução; o dry-run não acessa a rede. Etapas manuais ficam para login, licenças, firmware e escolhas pessoais. Não se usam Snap nem drivers proprietários por conveniência; nenhum aplicativo é instalado por dois gestores.

| Ferramentas | Método | Motivo e fonte |
|---|---|---|
| Git, Git LFS, curl, wget, unzip, zip, build-essential, jq, ripgrep, fd-find, fzf, bat, eza, htop, btop, tree, OpenSSH Client, rsync, Vim | APT da distribuição | Binários de sistema com atualizações integradas; `fdfind` e `batcat` recebem aliases Zsh. Ausência de candidato vira etapa manual. |
| GitHub CLI | Repositório APT oficial com chave em keyring dedicado | Atualizações pelo APT; a chave é comparada a fingerprints publicados em [GitHub CLI Linux install](https://github.com/cli/cli/blob/trunk/docs/install_linux.md). |
| Lazygit | APT se houver candidato; caso contrário, release oficial com digest SHA-256 | Mantém integração com APT quando disponível. [Releases](https://github.com/jesseduffield/lazygit/releases). |
| Warp | Repositório APT oficial assinado; preservar fonte do fornecedor e remover somente fonte redundante do script após validação e backup | Principal terminal; sem sandbox para acesso pleno a Git, SSH e CLI. [Instalação Warp](https://docs.warp.dev/getting-started/quickstart/installation-and-setup). |
| Ghostty | APT oficial do Ubuntu 26.04; manual nos demais | Evita pacote comunitário sem escolha explícita. [Instalação Ghostty](https://ghostty.org/docs/install/binary). |
| Zsh, Stow, [autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md), [syntax highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md) | APT da distribuição | O instalador confirma os dois scripts antes de configurar `.zshrc`; carrega syntax highlighting por último. |
| Starship, Zellij | APT se disponível; senão, release oficial com digest SHA-256 | Instalados em `~/.local/bin` quando não há pacote APT. [Starship](https://github.com/starship/starship/releases), [Zellij](https://github.com/zellij-org/zellij/releases). |
| mise | `extrepo` + APT | Fonte documentada para Debian 11+/Ubuntu 22.04+; mantém atualizações no APT. [Instalação mise](https://mise.jdx.dev/installing-mise.html). |
| Node LTS, pnpm, Bun | mise | Node nunca é instalado via APT/NVM. Projetos podem definir versões próprias. [Node no mise](https://mise.jdx.dev/lang/node.html). |
| TypeScript | Dependência de projeto | Evita versão global que diverge do projeto. |
| Docker Engine, CLI, Compose, Buildx | Fallback explícito via repositório Docker APT Ubuntu `noble` no Mint | Só é planejado com `INSTALL_DOCKER_ENGINE_FALLBACK=1` quando KVM não está disponível. [Ubuntu](https://docs.docker.com/engine/install/ubuntu/). |
| Docker Desktop | `.deb` e checksum da mesma versão baixados das notas oficiais, repositório Docker APT | Instalação primária quando KVM está acessível; aceite de termos e contexto `desktop-linux` após iniciar. [Ubuntu](https://docs.docker.com/desktop/setup/install/linux/ubuntu/), [notas](https://docs.docker.com/desktop/release-notes/). |
| Antigravity IDE e CLI | Tarball oficial por HTTPS; CLI com SHA-512 do manifesto oficial | O IDE não publica checksum na página; login permanece interativo. [Download](https://antigravity.google/download). |
| Claude Code, Codex CLI, OpenCode, Gemini CLI | Instaladores standalone oficiais para Claude/Codex/OpenCode; Gemini via npm com prefixo de usuário estável | Sem dependência dos diretórios Node do mise. Gemini usa Node ativo 20+, sem instalar outro runtime; sem `sudo npm` ou login automático. [Claude](https://docs.anthropic.com/en/docs/claude-code/getting-started), [Codex](https://help.openai.com/en/articles/11096431), [OpenCode](https://dev.opencode.ai/v2/docs), [Gemini](https://geminicli.com/docs/get-started/installation/). |
| Claude Desktop | Repositório APT oficial com verificação da versão-base Ubuntu/Debian | Beta oficial com fingerprint verificado; mapear um derivado à base não implica suporte oficial do fornecedor. [Claude Desktop Linux](https://support.claude.com/en/articles/10065433-install-claude-desktop). |
| ChatGPT Desktop | `.deb` oficial por HTTPS em Ubuntu 24.04/26.04 e Debian 13 | Prévia oficial, pacote validado por nome/arquitetura; a página não publica checksum. [ChatGPT Linux](https://learn.chatgpt.com/docs/linux/linux-app). |
| Ollama | Release oficial com digest SHA-256, serviço systemd | Pacote base instalado sem ROCm/modelos; backend específico requer teste com modelo. [Linux](https://docs.ollama.com/linux), [GPU](https://docs.ollama.com/gpu). |
| llama.cpp | Release Ubuntu Vulkan oficial com digest SHA-256 | Instala binários e bibliotecas no diretório do usuário. [Releases](https://github.com/ggml-org/llama.cpp/releases). |
| Vulkan tools, Mesa Vulkan drivers, pciutils | APT | Diagnóstico sem substituir o driver AMDGPU. |
| Android Studio, SDK, Platform Tools | Tarball Studio e ZIP Command-line Tools verificados; `sdkmanager` instala Platform Tools, plataforma e Build Tools estáveis | Reutiliza o SDK existente. Termos e licenças ficam interativos; não instala ADB via APT. [Studio](https://developer.android.com/studio/install), [SDK Manager](https://developer.android.com/tools/sdkmanager). |
| JDK 17 | APT, se apropriado | React Native recomenda JDK 17. [React Native](https://reactnative.dev/docs/set-up-your-environment). |
| Zen Browser | Flatpak oficial no Flathub | Método recomendado pelo Zen, isolamento de navegador; limita integração nativa específica. [Zen Linux](https://docs.zen-browser.app/guides/install-linux). |
| Vivaldi, Chrome | Repositórios APT oficiais assinados | Reutiliza fontes criadas pelos próprios pacotes; fontes redundantes do instalador são removidas somente após validação e backup. Não se altera o navegador padrão. [Vivaldi](https://help.vivaldi.com/desktop/install-update/manual-setup-vivaldi-linux-repositories/), [Chrome](https://www.google.com/linuxrepositories/). |
| Tailscale | Repositório APT estável oficial da base Ubuntu | Login é pessoal. [Linux](https://tailscale.com/docs/install/linux), [pacotes](https://dl.tailscale.com/stable/). |
| Slack | `.deb` oficial, assinatura `debsig` verificada | Linux beta; requer `debsig-verify` e a chave/política oficial da Slack. [Instalação](https://slack.com/help/articles/212924728-Download-Slack-for-Linux--beta-), [assinaturas](https://slack.com/help/articles/115004809166-Verify-Slack-for-Linux--beta--package-signatures). |
| DBeaver Community | Repositório APT oficial com keyring dedicado | Cliente visual para bancos de dados. [Downloads e instalação](https://dbeaver.io/download/). |
| Bruno | Repositório APT oficial com keyring dedicado | Cliente de API. [Downloads e instalação](https://www.usebruno.com/downloads). |
| GNOME Tweaks, Extension Manager, KDE Connect, Restic | APT | Utilitários GNOME só no GNOME; backup precisa destino explícito. |
| Timeshift ou Snapper | Manual | Exige verificar layout Btrfs antes de configurar snapshots. |

**Compatibilidade:** Pop!_OS, Zorin e Mint são detectados como distribuições próprias, com `UBUNTU_CODENAME` para diagnóstico. Mint pode usar a suite Ubuntu `noble` do repositório Docker quando os demais pré-requisitos passam; derivados não recebem suporte oficial do Docker. Revise conflitos antes de qualquer mudança de daemon.

## Aprovação e ações com impacto (0.2.0)

Toda ação planejada que altera arquivos ou o sistema exige digitar `apply` em um terminal antes da execução; `--yes` não pula essa etapa. Sem terminal de controle, o instalador cancela antes das alterações. Termos/licenças Android mantêm seus próprios prompts. O checklist pode abrir ferramentas e salvar marcações quando solicitado pelo usuário.

- Todas as instalações APT usam `--no-remove`: se uma transação exigir remover pacotes existentes, ela falha. Scripts dos pacotes podem iniciar serviços ou alterar dependências. Não há rollback automático.
- A limpeza de fontes redundantes do script para Warp, Claude Desktop, Chrome e Vivaldi cria backup em `~/.local/state/linux-dev-setup/repo-backups/` antes de remover o arquivo. As verificações variam por fornecedor. Restaurar uma fonte duplicada pode quebrar APT novamente.
- `.bashrc`, `.zshrc` e `.profile` recebem backups `.backup.TIMESTAMP` antes de substituir blocos gerenciados. Arquivos de comandos, launchers e symlinks do usuário podem ser substituídos; nem todos os binários recebem backup.
- A migração remove somente os pacotes npm antigos das quatro CLIs de IA após verificar a substituição. Não apaga versões Node, credenciais ou configuração. Gemini usa Node ativo 20+ em prefixo npm estável; não instala outro runtime nem configura um prefixo global do npm.
- KVM pode carregar módulos e adicionar o usuário ao grupo `kvm`; `chsh` pode mudar o shell de login. Novo login/senha podem ser necessários. Não altera firmware nem adiciona o usuário automaticamente ao grupo `docker`.
- Ollama extrai arquivos em `/usr`, cria conta/home `/usr/share/ollama` quando ausente, concede grupos render/video, instala unidade quando não existe, recarrega systemd e habilita/inicia o serviço. Para parar/desabilitar: `sudo systemctl disable --now ollama`. Antes de remover arquivos manualmente, confira propriedade e dados que deseja manter.
- Aplicativos e SDK ocupam espaço e podem substituir/atualizar ferramentas em seus diretórios. Nenhuma raiz SDK é excluída.

Instaladores nativos oficiais de Claude, Codex e OpenCode executam como usuário e gerenciam seus próprios downloads/verificações; o projeto não fixa independentemente todos os payloads. DBeaver verifica se a chave é interpretável por GPG; Bruno compara ID curto, uma validação mais fraca que fingerprint completo. Não há formatação de partições, mudanças de bootloader, reinício automático ou exclusão planejada de modelos/contêineres/volumes. Scripts externos continuam sendo uma fronteira de confiança.

[Instruções em português](../README.pt-BR.md) · [Detalhes em inglês](tooling.md)
