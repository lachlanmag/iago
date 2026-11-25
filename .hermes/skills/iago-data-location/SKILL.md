---
name: iago-data-location
description: >-
  Show or change where Iago stores job search data on this computer (in the
  repo, or a folder outside it that the user syncs with any tool). Use when
  the user says where is my iago data, move my data, change data folder, use
  iago on another computer, set up sync, data folder missing, or runs
  /iago-data-location. Does not sync files itself.
---

# Iago data location (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-data-location/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.hermes/skills/iago-data-location/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f "$HOME/.hermes/skills/iago-data-location"` → `REPO_ROOT` = parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | Find `scripts/link-data.sh` in a subfolder; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- New skills are discovered by new Hermes sessions after `install-skills.sh --platform hermes`; no reload needed.
