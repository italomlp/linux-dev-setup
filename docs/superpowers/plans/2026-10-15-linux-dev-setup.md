# Linux Development Setup Implementation Plan

> **For agentic workers:** Implement each task with a failing test first. This session uses native execution.

**Goal:** Build a safe, repeatable Bash installer for the requested Ubuntu/Debian development workstation.

**Architecture:** Modules register typed actions. A shared planner prints and executes the same ordered plan; unsupported operations become documented manual actions.

**Tech Stack:** Bash, APT, Flatpak, mise, shell tests.

**Spec:** `docs/superpowers/specs/2026-10-15-linux-dev-setup-design.md`

## Global constraints

- x86_64 Ubuntu, Debian, Zorin, Pop!_OS and Linux Mint only.
- No partition, bootloader, driver replacement, automatic login, model download, or secret storage.
- Dry-run performs no writes or network calls.
- Existing applications and configurations stay in place.

## Review focus

- Invalid module name must fail before any mutation.
- Missing APT metadata must not be interpreted as installable.
- Derivative codename must never be used directly in Docker's repository.
- Dry-run must not create logs, caches, or dotfiles.
- An existing alternate package format must not be installed again.

### Task 1: CLI and detection

**Files:** `install.sh`, `lib/detection.sh`, `tests/run.sh`

- [ ] Add failing CLI tests for help, list, invalid input, supported fixture and unsupported fixture.
- [ ] Implement parsing, detection and module selection.
- [ ] Run tests.

### Task 2: Planning and dispatch

**Files:** `lib/planning.sh`, `lib/package-manager.sh`, `lib/logging.sh`, `tests/run.sh`

- [ ] Add failing tests for dry-run read-only behavior, action categories and dependency order.
- [ ] Implement typed action registration, rendering, prompts, execution and failure handling.
- [ ] Run tests.

### Task 3: Workstation modules

**Files:** `modules/*.sh`, `config/*.conf`, `tests/run.sh`

- [ ] Add failing tests for selective modules, package detection, incompatible Docker and configuration preservation.
- [ ] Implement system, terminal, JavaScript, Docker, editors, agents, LLM, Android, applications and productivity modules.
- [ ] Run tests.

### Task 4: Documentation and verification

**Files:** `README.md`, `docs/tooling.md`, `tests/run.sh`

- [ ] Document install methods, limitations, verification and update strategy.
- [ ] Run Bash syntax checks, ShellCheck if available, and full tests.
- [ ] Inspect diff and report remaining host validation limits.
