# Changelog

## 0.2.0

- Repair duplicate Warp APT sources before package operations and after Warp installation, retaining the vendor source and backing up the redundant installer source.
- Migrate Claude Code, Codex and OpenCode to standalone installations. Keep Gemini in a stable user npm prefix using the active Node, without installing another runtime.
- Verify replacements before removing legacy AI npm packages from existing mise Node installations; preserve credentials and unrelated packages.
- Require explicit interactive `apply` approval for planned changes, including with `--yes`. Refuse APT transactions that remove installed packages and back up redundant Claude Desktop sources.
- Provide English and Brazilian Portuguese run instructions, module inventories, installation decisions, side effects and recovery limitations in release packages.
