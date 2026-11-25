---
name: iago-data-location
description: >-
  Show or change where Iago stores job search data on this computer (in the
  repo, or a folder outside it that the user syncs with any tool). Use when
  the user says where is my iago data, move my data, change data folder, use
  iago on another computer, set up sync, data folder missing, or runs
  /iago-data-location. Does not sync files itself.
---

# Iago data location (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-data-location/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/iago-data-location/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/iago-data-location"` → `REPO_ROOT` = parent of `.claude/skills` on resolved path |
| Nested under parent workspace | Find `scripts/link-data.sh` in a subfolder; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask multi-choice questions in chat (pick folder / type path / keep in repo).
- Run scripts with the Bash tool on the user's behalf; do not ask the user to type commands.
- After `install-skills.sh --platform claude` (or `--platform both`), restart or reload the Claude Code session if the skill does not appear.
