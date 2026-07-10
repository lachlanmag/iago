---
name: iago-pipeline-review
description: >-
  Review the open application pipeline, re-verify listings, rank roles by fit
  and urgency, and recommend which jobs to shortlist or apply to first. Use when
  the user asks to review the pipeline, prioritize applications, decide what to
  shortlist, triage discovered roles, what should I apply to first, which jobs
  should I shortlist, rank my open roles, weekly pipeline review, help me decide
  what to apply to this week, or runs /iago-pipeline or /pipeline-review.
---

# Pipeline review (LM Studio)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-pipeline-review/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/iago-pipeline-review/SKILL.md` | `REPO_ROOT` = workspace root |
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
- Ask in chat for bandwidth, shortlist promotions, or ambiguous names; re-run `/iago-pipeline-review` (or `/iago-pipeline`) manually when needed.
