---
name: iago-daily
description: >-
  Run the daily job search from your configured role priorities, surface new
  listings, and update the application tracker. Use when the user says daily
  job search, job hunt, find new jobs, run the job search, run the job search
  for today, check for jobs today, search for new roles, what's new on the
  boards, update the tracker from today's search, or runs /iago or /iago-daily.
---

# Daily job search (LM Studio)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-daily/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/iago-daily/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.lmstudio/skills` |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## LM Studio-specific

- Ask clarifying questions in chat (no Cursor `AskQuestion` tool).
- Read/write tracker and reports with plugin tools (`read_file`, `write_file`, `patch_file`).
- Run repo scripts with `run_command` (e.g. `bash "$REPO_ROOT/scripts/verify-workspace.sh"`).
- Web fetch: `run_command` + curl by default; optional [web-visit](https://lmstudio.ai/khtsly) if pages block curl.
- No headless runner and no `/loop`; re-activate the skill in chat. Automation is tracked in [#40](https://github.com/lachlanmag/iago/issues/40).
- Prefer `run_command` + curl for board/listing fetches; re-run `/iago-daily` in a new turn if the run stalls.
