# Changelog

## 0.2.1

- Replace standalone Antigravity IDE installation with Microsoft's official VS Code Debian package, retaining package-managed desktop integration and signed APT updates.
- Keep the standalone `agy` CLI; remove the IDE downloader and checklist entry. Neither standalone Antigravity IDE nor Antigravity app is installed.
- Add two ordered VS Code checklist steps: account review and verified Google Antigravity extension installation. Document signing in through `agy`, followed by reloading VS Code, within step 2.
- Block extension setup until account review, retain failed installation as pending, and skip reinstalling an existing extension.
- Update English and Brazilian Portuguese instructions, installation sources, side effects, and release commands; add mocked VS Code package and checklist regression tests.

## 0.2.0

- Repair duplicate Warp APT sources before package operations and after Warp installation, retaining the vendor source and backing up the redundant installer source.
- Migrate Claude Code, Codex and OpenCode to standalone installations. Keep Gemini in a stable user npm prefix using the active Node, without installing another runtime.
- Verify replacements before removing legacy AI npm packages from existing mise Node installations; preserve credentials and unrelated packages.
- Require explicit interactive `apply` approval for planned changes, including with `--yes`. Refuse APT transactions that remove installed packages and back up redundant Claude Desktop sources.
- Provide English and Brazilian Portuguese run instructions, module inventories, installation decisions, side effects and recovery limitations in release packages.
