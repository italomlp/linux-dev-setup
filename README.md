# Linux Dev Setup

Instalador Bash modular para um desktop x86_64 com Ubuntu, Debian, Zorin OS, Pop!_OS ou Linux Mint. O foco é preservar instalações e dados existentes. O plano é calculado antes de qualquer alteração e reutilizado na execução.

## Uso

```bash
./install.sh --list
./install.sh --dry-run
./install.sh --interactive --dry-run
./install.sh --interactive
./install.sh --all --dry-run
./install.sh --module javascript,docker,ai-agents --dry-run
./install.sh --all
./install.sh --module android --yes
```

Sem argumentos, o script faz dry-run de todos os módulos. Com `--interactive`, um menu permite escolher módulos por número (separados por vírgula), todos com `0`, ou sair com `q`. Ao escolher Docker ou Applications, o menu também pergunta se deve incluir Docker Desktop ou Flatpak e Zen. O plano é mostrado antes da execução; sem `--dry-run`, o instalador pede uma confirmação final. `--yes` permite execução sem essa confirmação. O script deve ser iniciado como usuário normal; ele solicita `sudo` somente para ações de sistema. Não execute com `sudo ./install.sh`.

Módulos: `system`, `terminal`, `javascript`, `docker`, `editors`, `ai-agents`, `local-llms`, `android`, `applications`, `productivity`.

`config/settings.conf` permite desligar Docker Desktop ou Flatpak com `INSTALL_DOCKER_DESKTOP=0` e `INSTALL_FLATPAK=0`. `config/packages.conf` lista os pacotes essenciais. No módulo `ai-agents`, a dependência mise/Node é planejada automaticamente se estiver ausente.

## Pacote para GitHub Releases

Crie os arquivos de distribuição com:

```bash
bash scripts/package.sh --repo italomlp/linux-apps-installer
```

O comando gera `dist/linux-dev-setup-v0.1.0.tar.gz`, seu `.sha256` e `dist/install.sh`, usando a versão em `VERSION`. O `install.sh` remoto baixa o pacote da mesma versão publicada, confere o SHA-256, extrai em um diretório temporário e inicia o instalador. O pacote contém os scripts, módulos, configuração e documentação necessários, sem exigir um clone do repositório. Sem `--repo`, o build gera apenas o pacote e o checksum. Para criar um release, faça commit, publique este projeto em um repositório GitHub e envie uma tag que corresponda ao `VERSION`:

```bash
git add .
git commit -m "Prepare v0.1.0 release"
git push -u origin main
git tag v0.1.0
git push origin v0.1.0
```

O workflow em `.github/workflows/release.yml` roda os testes, monta o pacote com o nome real do repositório e publica os três arquivos no GitHub Release. Para novas versões, altere `VERSION`, faça commit e crie uma tag correspondente. Se preferir publicar manualmente, carregue os três arquivos de `dist/` como assets do release.

Depois de publicado, o comando de uma linha usa o `install.sh` do release mais recente:

```bash
curl -fsSL https://github.com/italomlp/linux-apps-installer/releases/latest/download/install.sh | bash
```

Sem argumentos, esse comando abre o menu interativo em um terminal. Para passar opções, use, por exemplo, `curl -fsSL https://github.com/italomlp/linux-apps-installer/releases/latest/download/install.sh | bash -s -- --module javascript --dry-run`.

Em outra máquina Linux, também é possível baixar o release manualmente:

```bash
REPO=italomlp/linux-apps-installer
VERSION=v0.1.0
curl -fLO "https://github.com/$REPO/releases/download/$VERSION/linux-dev-setup-$VERSION.tar.gz"
curl -fLO "https://github.com/$REPO/releases/download/$VERSION/linux-dev-setup-$VERSION.tar.gz.sha256"
sha256sum -c "linux-dev-setup-$VERSION.tar.gz.sha256"
tar -xzf "linux-dev-setup-$VERSION.tar.gz"
cd "linux-dev-setup-$VERSION"
./install.sh --interactive
```

Confira o plano antes de confirmar a instalação. Os passos acima não exigem Git na máquina de destino.

## Exemplo de dry-run

```text
System: ubuntu 24.04 | base: noble | architecture: x86_64 | desktop: GNOME

Will install:
  - Node.js LTS via mise — User install; no APT Node or NVM
      operation: mise use -g node@lts

Manual intervention:
  - Docker Desktop — Requires supported release and KVM; see official instructions
```

As categorias `Already installed`, `Will install`, `Will configure`, `Skipped` e `Manual intervention` aparecem conforme o estado encontrado. `Will update` e `Unsupported` são reservadas para futuras operações; a versão atual não atualiza aplicativos já instalados nem remove pacotes. O dry-run do instalador local não cria logs, dotfiles, caches ou repositórios e não faz acesso à rede. O método remoto precisa baixar e verificar o pacote antes de iniciar esse dry-run. Consultas locais como `dpkg-query`, `apt-cache`, `command -v` e `flatpak info` são usadas para detectar o estado.

## O que é automatizado

- Pacotes disponíveis nos repositórios APT já configurados, inclusive ferramentas essenciais e utilitários do desktop.
- Repositórios assinados do GitHub CLI, Warp, Claude Desktop e Docker Engine em sistemas oficialmente suportados.
- mise via `extrepo`, Node LTS, pnpm e Bun via mise; CLIs de IA via npm executado pelo Node do mise.
- Flatpak e o remoto Flathub do usuário; Zen Browser pelo ID oficial `app.zen_browser.zen`.
- Blocos limitados para Zsh, Bash e Android em arquivos do usuário, com cópia de segurança antes de alterar arquivos existentes.

As escolhas por ferramenta e links oficiais estão em [docs/tooling.md](docs/tooling.md). O script não atualiza uma instalação existente por conta própria. Reexecute para instalar componentes que faltavam; para atualização, use o gerenciador que instalou cada ferramenta.

## Etapas manuais

O plano registra ações manuais para artefatos cujo URL/checksum oficial muda, aceites de licença, login ou mudanças que dependem do hardware e da configuração atual. Entre elas: Docker Desktop, ChatGPT Desktop, Antigravity, Android Studio/SDK, Ollama, llama.cpp, Chrome, Vivaldi, Tailscale e snapshots. Isso evita executar um instalador remoto sem verificação ou adivinhar um pacote de distribuição. Os links oficiais e comandos sugeridos aparecem no plano.

Docker Desktop usa o contexto `desktop-linux` e imagens/volumes separados do Engine nativo (`default`). Antes de usar os dois, confira `docker context ls`. Não há parada automática de daemons, alteração de portas, volumes, diretório de dados ou inclusão automática no grupo `docker`. O grupo `docker` dá privilégios equivalentes a root; a decisão deve ser consciente.

## Verificação depois da instalação

```bash
git --version && gh --version && rg --version
mise --version && mise exec node@lts -- node --version
mise exec node@lts -- npm --version
docker context ls && docker compose version && docker buildx version
flatpak info app.zen_browser.zen
vulkaninfo --summary
java -version && adb version
```

Para Docker Engine: `sudo docker info`. Para Desktop, inicie o aplicativo, aceite os termos, então use `docker context use desktop-linux` e `docker info`. Para Ollama: depois de carregar voluntariamente um modelo, use `ollama ps` e examine o processador. Para llama.cpp: execute `llama-cli --list-devices` após compilá-lo com Vulkan. Nenhum modelo é baixado pelo instalador.

`./diagnose.sh` reúne GPU, VRAM (quando exposta por sysfs), Vulkan, KVM, backends locais e contextos Docker em uma consulta somente leitura.

## Testes e limites

```bash
bash tests/run.sh
for file in install.sh diagnose.sh scripts/*.sh scripts/*.in lib/*.sh modules/*.sh config/*.conf tests/run.sh; do bash -n "$file" || exit; done
shellcheck install.sh lib/*.sh modules/*.sh tests/run.sh
```

Os testes usam metadados falsos de distribuição e cobrem parser, módulos, dry-run e distribuição não suportada. Não instalam pacotes. A execução real ainda precisa ser verificada em uma VM ou instalação Linux correspondente; este projeto foi escrito em macOS, sem executar alterações APT/Flatpak reais.

Suporte de terceiros não é igual a suporte da distribuição: Docker não testa derivados Ubuntu/Debian; por isso o script não configura automaticamente o repositório Docker neles. Ghostty usa o pacote Ubuntu oficial somente quando disponível no Ubuntu 26.04. `apt-cache` sem índices atualizados pode classificar um pacote como manual; execute `sudo apt-get update` fora do instalador e repita o dry-run. O instalador não modifica partições, bootloader, Btrfs, drivers, configurações do Warp/Ghostty/Antigravity ou navegador padrão. Ele não inicia serviços explicitamente; pacotes APT podem ativar serviços durante a instalação.

## Manutenção

Antes de rodar novamente, revise `./install.sh --all --dry-run`. Atualize pacotes APT com o ciclo normal da distribuição, Flatpaks com `flatpak update --user`, ferramentas mise com `mise upgrade`, e aplicativos de download manual seguindo seus canais oficiais. Verifique periodicamente os IDs, repositórios e requisitos em [docs/tooling.md](docs/tooling.md); métodos de instalação mudam.

Logs de execução real ficam em `~/.local/state/linux-dev-setup/`, com permissão `0600`. O dry-run não cria esse diretório. Se uma ação falhar, as seguintes independentes continuam e o resumo indica falhas e dependências puladas. Corrija o problema e reexecute o módulo.
