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

# Resume feedback (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/resume-feedback/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/resume-feedback/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/resume-feedback` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
