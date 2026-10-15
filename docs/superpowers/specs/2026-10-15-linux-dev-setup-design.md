# Linux development setup design

The installer targets one x86_64 Debian-family desktop at a time. It detects the actual distribution, Ubuntu base codename for derivatives, desktop, package tools, virtualization, and existing programs before proposing work. Unsupported systems receive a read-only diagnostic and no mutations.

Every module adds typed actions to one in-memory plan. The same ordered actions are printed by dry-run and dispatched during execution. No module runs installation commands while planning. The action dispatcher owns APT, official repositories, Flatpak, mise, user dotfiles and manual follow-ups. It refuses unknown action types; it never uses `eval`.

APT handles distribution packages. Official repositories are added with dedicated keyrings and `Signed-By`, preserving existing repository files. Flatpak is used only for Zen on Flathub. mise exclusively owns Node, pnpm and Bun versions. Existing executables are retained. Opaque downloads, installers requiring unverified checksums, login, license acceptance, BIOS/driver changes and destructive migrations become explicit manual actions with official links.

Docker Engine uses Docker's stable Ubuntu/Debian repository only on directly supported releases; derivative systems keep an existing Engine or receive a manual compatibility item. Docker Desktop is a separate manual installation with KVM checks and context guidance. No daemon is stopped automatically, and no volumes or data directories are touched.

Execution confirms the plan, unless `--yes` is set. Root is requested per action, not for the whole script. A failed action is recorded; independent later actions continue, but dependent actions are skipped. Logs are user-owned and created only for a real run. Shell snippets are appended only if absent and existing files are backed up first. No automatic login, model download, browser default change, shell default change, or reboot occurs.

Tests run the CLI against fixture OS metadata with dry-run and stub executables. They check parsing, selection, read-only behavior, unsupported platforms, and action ordering. A Linux VM is still needed before claiming real installation success.
