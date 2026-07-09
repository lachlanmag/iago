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

# Pipeline review (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-pipeline-review/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/iago-pipeline-review/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/iago-pipeline-review"` → parent of `.claude/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask clarifying questions in chat when the workflow requires user input (bandwidth, shortlist promotions, ambiguous company names).
