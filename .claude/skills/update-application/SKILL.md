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

# Update application (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/update-application/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/update-application/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/update-application"` → parent of `.claude/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask clarifying questions in chat when the workflow requires user input (ambiguous company/title, status transitions, dates, channels).
