---
name: iago-setup
description: >-
  Guided job search onboarding that picks the data folder, initializes data/
  files, and writes config.yaml from conversation. Use when the user says set
  up job search, configure job search, job search onboarding, first time
  setup, initialize job search, help me configure iago, or runs /iago-setup.
---

# Iago setup (Cursor)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-setup/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before any file access or script. All Iago paths and scripts use `$REPO_ROOT` (e.g. `$REPO_ROOT/data/config.yaml`, `bash "$REPO_ROOT/scripts/init-data.sh"`).

| Method | When |
|--------|------|
| Workspace contains `.cursor/skills/iago-setup/SKILL.md` | `REPO_ROOT` = Cursor workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.cursor/skills` |
| Global skill symlink | `readlink -f "$HOME/.cursor/skills/iago-setup"` → `REPO_ROOT` = parent of `.cursor/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Cursor-specific

- Use `AskQuestion` for multi-choice (work model, role order, board toggles, setup mode, workspace layout).
- After `install-skills.sh --platform cursor` (or `--platform both`), tell user: Cmd+Shift+P → Developer: Reload Window.
