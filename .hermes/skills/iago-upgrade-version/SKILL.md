---
name: iago-upgrade-version
description: >-
  Upgrade the local Iago clone to the latest version from GitHub: git pull,
  merge new config keys, and refresh skill symlinks when needed. Use when the
  user says upgrade iago version, upgrade version, get latest iago, check for
  iago updates, sync iago, refresh iago, pull latest iago, or runs
  /iago-upgrade-version. Not for application tracker changes (use
  update-application).
---

# Iago upgrade version (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-upgrade-version/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/iago-upgrade-version/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/iago-upgrade-version` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
- After a git pull/version upgrade, re-run `install-skills.sh --platform hermes` to refresh local skill symlinks.
