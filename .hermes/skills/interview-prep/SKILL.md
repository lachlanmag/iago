---
name: interview-prep
description: >-
  Build interview talking points, STAR stories, and questions to ask from the JD,
  resume, and any company brief. Runs automatically when an application is
  submitted (status applied via update-application). Use when the user applies,
  asks for interview prep, talking points, interview prep for [Company], talking
  points for [role], help me prep for [Company] interview, STAR stories for
  [Company], questions to ask [Company], or runs /iago-interview or
  /interview-prep.
---

# Interview prep (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/interview-prep/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/interview-prep/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/interview-prep` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
