---
name: iago-setup
description: >-
  Guided job search onboarding that initializes gitignored data/ files and
  writes config.yaml from conversation. Use when the user says set up job
  search, configure job search, job search onboarding, first time setup,
  initialize job search, help me configure iago, or runs /iago-setup.
---

# Iago setup (LM Studio)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-setup/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/iago-setup/SKILL.md` | `REPO_ROOT` = workspace root |
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
- Walk setup one section at a time in chat (work model, roles, boards, resume path).
- After install, remind the user to set khtsly Skills Directory if skills are missing.
