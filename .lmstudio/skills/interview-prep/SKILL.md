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

# Interview prep (LM Studio)

**Mandatory:** Read and follow `$REPO_ROOT/skills/interview-prep/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/interview-prep/SKILL.md` | `REPO_ROOT` = workspace root |
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
- Ask in chat when company/title or JD/resume paths are ambiguous.
