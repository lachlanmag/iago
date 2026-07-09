---
name: iago-setup
description: >-
  Guided job search onboarding that initializes gitignored data/ files and
  writes config.yaml from conversation. Use when the user says set up job
  search, configure job search, job search onboarding, first time setup,
  initialize job search, help me configure iago, or runs /iago-setup.
---

# Iago setup (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-setup/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before any file access or script. All Iago paths and scripts use `$REPO_ROOT` (e.g. `$REPO_ROOT/data/config.yaml`, `bash "$REPO_ROOT/scripts/init-data.sh"`).

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/iago-setup/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/iago-setup"` → `REPO_ROOT` = parent of `.claude/skills` on resolved path |
| Nested under parent workspace | Find `scripts/verify-workspace.sh` in a subfolder; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask multi-choice questions in chat (work model, role order, board toggles, setup mode, workspace layout).
- After `install-skills.sh --platform claude` (or `--platform both`), restart or reload the Claude Code session if skills do not appear.
