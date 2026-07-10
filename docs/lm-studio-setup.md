# LM Studio setup (interactive)

Run Iago skills inside **LM Studio chat** using the [khtsly/skills](https://lmstudio.ai/khtsly/skills) plugin. Canonical workflows live in `skills/`; LM Studio entrypoints are thin wrappers under `.lmstudio/skills/`.

Headless / scheduled runs are **not** covered here. See [#40](https://github.com/lachlanmag/iago/issues/40).

## Prerequisites

- [LM Studio](https://lmstudio.ai/) with a **tool-capable** local model
  - Recommended: `qwen/qwen2.5-coder-14b` or `qwen/qwen3.5-9b`
- Network access for job boards
- This Iago clone on disk

## 1. Install the skills plugin

1. Open LM Studio → Hub (or Plugins).
2. Install **[khtsly/skills](https://lmstudio.ai/khtsly/skills)**.
3. Do not use other skills-plugin forks for this guide (unsupported in v1).

## 2. Point the plugin at Iago wrappers

From your clone:

```bash
cd /path/to/iago
bash scripts/install-skills.sh --platform lmstudio
```

Copy the printed **Skills Directory Path** (it should end in `.lmstudio/skills`).

In the khtsly/skills plugin settings, set **Skills Directory** to that absolute path.

## 3. Open chat on the repo root

In LM Studio, open a chat whose **workspace / project folder** is the Iago repo root (the folder that contains `skills/`, `.lmstudio/`, `scripts/`, and `data/`).

If the workspace is a parent folder, either reopen on the Iago root or set `REPO_ROOT` when the skill asks.

## 4. Preflight

```bash
bash scripts/verify-lm-studio.sh
```

Expect `lmstudio_skills=yes` and a printed `skills_directory_path`.

## 5. First-time setup

In LM Studio chat:

```text
/iago-setup
Set up job search
```

Complete the prompts in chat. This should create or update `data/config.yaml`.

## 6. Daily search

```text
/iago-daily
Run the daily job search for today
```

Expect updates under `data/daily-runs/` and `data/applications.yaml` (or your configured tracker).

### Fetching pages

- Default: `run_command` + `curl`
- If a site blocks curl or is a heavy SPA, install khtsly **web-visit** (optional) and retry
- Record gaps in the daily report rather than inventing listings

## 7. Other skills

khtsly activates skills with `/<folder-name>` (for example `/iago-daily`). Frontmatter also lists Cursor-style aliases (`/iago-pipeline`, `/pipeline-review`, and so on); if a short alias does not expand, use the folder name form.

| Skill | Example |
|-------|---------|
| Pipeline review | `/iago-pipeline-review` |
| Update tracker | `/update-application` |
| Company brief | `/company-research` |
| Resume feedback | `/resume-feedback` |
| Interview prep | `/interview-prep` |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Skill not found / empty skills list | Re-check Skills Directory path; re-run `install-skills.sh --platform lmstudio` |
| Writes go to the wrong folder | Workspace must be the Iago repo root |
| Model ignores tools | Switch to a stronger coder model; shorten the turn |
| Curl fails on boards | Try web-visit plugin, or note the gap and continue |
| Need unattended daily runs | Out of scope here → [#40](https://github.com/lachlanmag/iago/issues/40) |

## Related

- Design: `docs/superpowers/specs/2026-07-10-lm-studio-interactive-skills-design.md`
- Claude Code / Cursor: see README Getting Started
- Automation follow-up: [#40](https://github.com/lachlanmag/iago/issues/40)
