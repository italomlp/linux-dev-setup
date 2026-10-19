# Linux Dev Setup

Instalador Bash modular para desktops x86_64 com Ubuntu, Debian, Linux Mint, Pop!_OS ou Zorin OS. Confira o plano, escolha módulos e aprove as alterações. Execute como usuário normal; o instalador solicita `sudo` quando necessário.

[English](README.md) · [Decisões e métodos de instalação](docs/tooling.pt-BR.md)

## Executar pelo release (sem Git)

Você precisa de Bash, curl, tar, Python 3 e `sha256sum`. Baixe, verifique e extraia a versão **0.2.0**:

```bash
curl -fLO https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.0/linux-dev-setup-v0.2.0.tar.gz
curl -fLO https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.0/linux-dev-setup-v0.2.0.tar.gz.sha256
sha256sum -c linux-dev-setup-v0.2.0.tar.gz.sha256 && \
  tar -xzf linux-dev-setup-v0.2.0.tar.gz && \
  cd linux-dev-setup-v0.2.0 && \
  ./install.sh --interactive --dry-run && \
  ./install.sh --interactive
```

Continue somente se o checksum mostrar `OK`. Ele detecta corrupção, mas vem do mesmo release e não é uma assinatura independente.

Outra opção é baixar o launcher, inspecioná-lo e executá-lo. Ele baixa e verifica automaticamente o release correspondente:

```bash
curl -fL https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.0/install.sh -o linux-dev-setup-launcher.sh
less linux-dev-setup-launcher.sh
bash linux-dev-setup-launcher.sh --interactive --dry-run
bash linux-dev-setup-launcher.sh --interactive
```

Para instalar com um comando de uma linha, execute o launcher diretamente:

```bash
curl -fsSL https://github.com/italomlp/linux-dev-setup/releases/download/v0.2.0/install.sh | bash
```

Isso abre o menu de módulos, verifica o arquivo do release e pede aprovação antes de aplicar alterações. Para apenas simular, substitua `bash` por `bash -s -- --interactive --dry-run`.

## Executar pelo código-fonte (sem baixar release)

```bash
git clone https://github.com/italomlp/linux-dev-setup.git
cd linux-dev-setup
./install.sh --interactive --dry-run
./install.sh --interactive
```

Para usar exatamente o código do release, execute `git checkout v0.2.0` antes do instalador. A branch padrão pode conter alterações mais recentes.

## Escolher o que instalar

```bash
./install.sh --list                                  # Listar módulos
./install.sh                                         # Simular todos; não altera nada
./install.sh --module terminal,ai-agents --dry-run     # Simular módulos selecionados
./install.sh --module terminal,ai-agents               # Executar os módulos selecionados
./install.sh --all --dry-run                          # Simular tudo
./install.sh --all                                    # Executar tudo
./install.sh --checklist                              # Concluir logins e pendências
./install.sh --checklist --dry-run                    # Consultar pendências sem alterar estado
./diagnose.sh                                         # Diagnóstico de GPU, KVM e Docker
```

`--interactive` permite escolher módulos por número. `0` seleciona todos; `q` sai. Docker Desktop e Flatpak/Zen têm perguntas adicionais no menu. Instalações existentes são normalmente mantidas; a migração de CLIs de IA e os reparos de repositórios são exceções intencionais.

Nunca use `sudo ./install.sh`. Revise o plano antes de executar. `--yes` pula a pergunta inicial de sim/não, **mas não pula a confirmação explícita `apply` para alterações**. Sem terminal de controle, nenhuma alteração é aplicada. Termos/licenças Android e autenticação continuam interativos.

### Módulos

| Módulo | O que instala ou configura |
|---|---|
| `system` | Git, Git LFS, GitHub CLI, Lazygit; curl, wget, zip/unzip, build-essential, jq, ripgrep, fd, fzf, bat, eza, htop, btop, tree, cliente OpenSSH, rsync e Vim. |
| `terminal` | Zsh, GNU Stow, Zellij, Starship, autosuggestions/syntax highlighting, Warp; Ghostty no Ubuntu 26.04 compatível. Gerencia a configuração Zsh e oferece mudar o shell de login. |
| `javascript` | mise, Node LTS, pnpm e Bun. Ativa mise no Bash. TypeScript fica como dependência do projeto. |
| `docker` | Docker Desktop quando sistema-base e KVM permitem; módulos/permissões KVM quando necessário. Engine, CLI, containerd, Compose e Buildx são apenas um fallback explícito. |
| `editors` | Vim e Google Antigravity IDE. |
| `ai-agents` | Claude Code, Codex e OpenCode standalone; Gemini CLI em prefixo npm estável usando Node ativo 20+. Antigravity CLI, Claude Desktop e ChatGPT Desktop quando compatíveis. Migra cópias npm antigas do mise. |
| `local-llms` | Ollama e seu serviço systemd, llama.cpp com Vulkan quando compatível; Vulkan tools, drivers Mesa Vulkan, pciutils e zstd conforme necessário. Não baixa modelos. |
| `android` | JDK existente ou OpenJDK 17; Android Studio, Command-line Tools, Platform Tools, plataforma/Build Tools estáveis mais recentes, ambiente SDK e KVM. Licenças exigem aceite. |
| `applications` | Flatpak/Flathub e Zen; Vivaldi, Chrome, Tailscale, DBeaver, Bruno e Slack. Mantém fontes válidas do fornecedor e limpa fontes redundantes de navegadores criadas pelo script. |
| `productivity` | GNOME Tweaks e Extension Manager no GNOME; KDE Connect e Restic. Layout de snapshots, destino de backup e retenção ficam manuais. |

A disponibilidade depende do sistema, repositórios, arquitetura e instalações existentes. Escolhas incompatíveis aparecem como etapas manuais.

### Configurações

Edite `config/settings.conf` ou defina variáveis para uma execução:

```bash
INSTALL_DOCKER_DESKTOP=0 INSTALL_FLATPAK=0 ./install.sh --all --dry-run
INSTALL_DOCKER_ENGINE_FALLBACK=1 ./install.sh --module docker --dry-run
```

Padrões: Docker Desktop e Flatpak habilitados; fallback Engine desabilitado. O fallback verifica pacotes de contêiner conflitantes e não os remove automaticamente. Pacotes essenciais ficam em `config/packages.conf`.

## Reparos, métodos e atualizações

- Pacotes de sistema usam APT preferencialmente, com repositórios oficiais assinados quando necessário. Não usa Snap. APT recusa transações que removeriam pacotes existentes.
- Runtimes de desenvolvimento ficam no mise, com versões por projeto. Claude/Codex/OpenCode usam instaladores oficiais standalone, expostos em `~/.local/bin`.
- Gemini usa `npm install --global --prefix "$HOME/.local/share/linux-dev-setup/npm" @google/gemini-cli`. O launcher estável usa o Node ativo. O módulo de IA não instala outro Node nem altera a configuração global do npm. Selecione Node 20+ antes de usar Gemini.
- Reexecute `terminal,ai-agents` para reparar fontes Warp e migrar CLIs. Pacotes npm antigos são removidos dos prefixos Node existentes no mise somente após verificar as substituições. Credenciais/configurações são preservadas. Abra outro terminal depois.
- Downloads oficiais usam checksums/assinaturas publicados quando disponíveis. ChatGPT Desktop e Antigravity IDE usam HTTPS e validação do pacote/arquivo, sem checksum publicado. Instaladores nativos das CLIs gerenciam seus próprios downloads. Veja [métodos e efeitos](docs/tooling.pt-BR.md).

Para atualizar: use APT, `flatpak update --user` ou `mise upgrade`, conforme a ferramenta. Claude usa seu atualizador nativo; Codex pode ser atualizado repetindo o instalador oficial; OpenCode usa `opencode upgrade`. Para Gemini, repita o comando npm com prefixo explícito acima. Reexecutar o script verifica instalações existentes e instala o que falta; não é uma atualização geral.

## Alterações que exigem aprovação

Antes da execução, o instalador lista as ações que alteram o sistema e exige digitar **`apply` em um terminal**. Isso inclui pacotes/repositórios, substituição de blocos de configuração ou binários, remoção de pacotes antigos de IA e os efeitos abaixo. Recusar cancela antes das ações planejadas. `--yes` não concede essa autorização.

| Efeito | Proteção / recuperação |
|---|---|
| Adicionar fontes/chaves APT e pacotes; scripts dos pacotes podem iniciar serviços ou alterar dependências. | Plano e aprovação explícita; `--no-remove` recusa remoção de pacotes. A instalação não tem reversão automática. |
| Remover fontes redundantes do script para Warp, Claude Desktop, Chrome ou Vivaldi. | Mantém a fonte do fornecedor, exige as verificações correspondentes e salva cópias em `~/.local/state/linux-dev-setup/repo-backups/`. O reparo Warp também ocorre após instalar Warp. |
| Substituir blocos gerenciados em `.bashrc`, `.zshrc`, `.profile`; substituir comandos/symlinks do usuário. | Arquivos de shell existentes recebem `.backup.TIMESTAMP` ao lado. Configuração externa aos blocos é mantida. Nem todos os binários do usuário recebem backup. |
| Desinstalar os quatro pacotes npm antigos de IA nos prefixos Node do mise. | Verifica substituições antes; mantém credenciais/configurações e pacotes não relacionados. Não exclui versões Node. |
| Carregar módulos KVM; adicionar seu usuário ao grupo `kvm`; mudar o shell com `chsh`. | Aprovação explícita; mudança de shell pode pedir senha. Shell/grupos podem exigir novo login. Não adiciona automaticamente ao grupo `docker`. |
| Instalar Ollama em `/usr`, criar conta de serviço, conceder acesso render/video e habilitar/iniciar `ollama.service`. | Aprovação explícita. Mantém serviço existente; uma CLI Ollama existente normalmente impede reinstalação. Para parar depois: `sudo systemctl disable --now ollama`. |

Não há formatação de partições, alteração de bootloader, reinício automático, exclusão de contêineres/volumes ou alteração do layout de snapshots no plano. O instalador não configura backups nem baixa modelos LLM. Instaladores de fornecedores e scripts dos pacotes são uma fronteira de confiança externa; confira plano e fontes antes de aprovar.

## Depois de executar

Use `./install.sh --checklist` para logins e licenças pendentes. Confirmações manuais ficam em `~/.local/state/linux-dev-setup/checklist.done`, sem credenciais. Inicie Docker Desktop e aceite os termos antes de selecionar `desktop-linux`; esse contexto tem contêineres/imagens/volumes separados do `default` do Engine.

Logs ficam em `~/.local/state/linux-dev-setup/`, com permissão `0600`. Falhas pulam dependentes; ações independentes podem continuar. Corrija a causa e repita o módulo. Não existe rollback completo do sistema. O dry-run local não cria estado persistente de instalação nem acessa a rede; o launcher precisa baixar o release antes de simular.

## Testar e gerar pacote

```bash
bash tests/run.sh
bash scripts/package.sh --repo italomlp/linux-dev-setup
```

Testes usam diretórios temporários e comandos de instalação simulados. O build lê `VERSION` e gera arquivo, checksum e launcher em `dist/`. O workflow testa pushes e publica os três arquivos quando uma tag `vVERSION` é enviada. A versão 0.2.0 usa a tag `v0.2.0`.
