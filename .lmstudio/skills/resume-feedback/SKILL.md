---
name: resume-feedback
description: >-
  Review a resume against a job description for role fit, ATS readiness, and
  hiring recommendation. Uses standalone markdown from profile.resume_path by
  default, or optional tailored Resume-Matcher JSON when enabled. Use when the
  user asks for resume feedback, ATS review, tailoring quality check, hiring
  review, review my resume, review my tailored resume, ATS review for [Company],
  check my resume against the JD, tailoring quality check, is this resume ready
  to submit, or runs /iago-feedback or /resume-feedback.
---

# Resume feedback (LM Studio)

**Mandatory:** Read and follow `$REPO_ROOT/skills/resume-feedback/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/resume-feedback/SKILL.md` | `REPO_ROOT` = workspace root |
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
- Ask in chat when JD path or resume source is ambiguous.
