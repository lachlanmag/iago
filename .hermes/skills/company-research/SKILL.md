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

# Company research (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/company-research/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/company-research/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/company-research` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
