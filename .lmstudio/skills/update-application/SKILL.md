---
name: update-application
description: >-
  Update pipeline status and dates in applications.yaml. Automatically runs
  company-research when a role is shortlisted and interview-prep when an
  application is submitted. Use when the user shortlists, applies, rejects,
  withdraws, moves to interview, updates tracker status, says shortlist
  [Company], set [Company] to applied, mark [Company] as rejected, withdraw
  [Company], move [Company] to interview, update my tracker, I applied to
  [Company], reject [Company], or runs /iago-update or /update-application.
---

# Update application (LM Studio)

**Mandatory:** Read and follow `$REPO_ROOT/skills/update-application/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/update-application/SKILL.md` | `REPO_ROOT` = workspace root |
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
- After shortlist/apply writes, follow WORKFLOW chaining into company-research / interview-prep in the same turn when possible.
