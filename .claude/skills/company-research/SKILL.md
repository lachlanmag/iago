---
name: company-research
description: >-
  Produce a role brief for a shortlisted job from the listing, company site, and
  tracker context. Runs automatically when a role is promoted to shortlisted
  (via update-application or pipeline-review). Use when the user shortlists a
  role, asks for a company brief, role brief, research [Company], company brief
  for [Company], role brief for [Company], brief on this role, tell me about
  [Company] for this role, prep a brief before I apply, or runs /iago-brief or
  /company-research.
---

# Company research (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/company-research/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/company-research/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/company-research"` → parent of `.claude/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask clarifying questions in chat when company/title or JD source is ambiguous.
- Chained from `update-application` or `iago-pipeline-review` in the same turn after shortlist writes.
