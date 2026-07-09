---
name: iago-daily
description: >-
  Run the daily job search from your configured role priorities, surface new
  listings, and update the application tracker. Use when the user says daily
  job search, job hunt, find new jobs, run the job search, run the job search
  for today, check for jobs today, search for new roles, what's new on the
  boards, update the tracker from today's search, or runs /iago or /iago-daily.
---

# Daily job search (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-daily/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/iago-daily/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/iago-daily"` → parent of `.claude/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask clarifying questions in chat when the workflow requires user input.
- Headless scheduled runs are Cursor-only for now ([#34](https://github.com/lachlanmag/iago/issues/34)).
