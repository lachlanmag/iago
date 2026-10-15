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

# Update application (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/update-application/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/update-application/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/update-application` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
