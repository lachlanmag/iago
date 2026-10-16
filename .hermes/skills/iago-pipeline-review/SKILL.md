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

# Pipeline review (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-pipeline-review/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/iago-pipeline-review/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/iago-pipeline-review` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
