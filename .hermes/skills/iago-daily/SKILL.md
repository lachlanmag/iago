---
name: iago-daily
description: >-
  Run the daily job search from your configured role priorities, surface new
  listings, and update the application tracker. Use when the user says daily
  job search, job hunt, find new jobs, run the job search, run the job search
  for today, check for jobs today, search for new roles, what's new on the
  boards, update the tracker from today's search, or runs /iago or /iago-daily.
---

# Daily job search (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-daily/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/iago-daily/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/iago-daily` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
- To schedule the daily search, run `hermes cron create "0 9 * * *" "bash \"$REPO_ROOT/scripts/run-daily-search.sh\" --agent hermes"`.
