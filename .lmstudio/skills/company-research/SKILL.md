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

# Company research (LM Studio)

**Mandatory:** Read and follow `$REPO_ROOT/skills/company-research/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/company-research/SKILL.md` | `REPO_ROOT` = workspace root |
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
- Ask in chat when company/title or JD source is ambiguous.
- For SPA/career pages that block curl, try optional khtsly web-visit.
