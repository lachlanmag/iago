# Iago (Pi / local agent)

This repo is a job search assistant. Personal state lives in gitignored `data/`. Skills live in `.cursor/skills/` (Agent Skills standard; Pi reads them from `.pi/skills/` symlinks too).

## REPO_ROOT

When this folder is the working directory, `REPO_ROOT` is the current directory. All paths are relative to here unless noted.

## Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `iago-daily` | `/skill:iago-daily` | Daily job search and tracker updates |
| `iago-pipeline-review` | `/skill:iago-pipeline-review` | Triage and prioritize pipeline |
| `iago-setup` | `/skill:iago-setup` | First-time onboarding |
| `update-application` | `/skill:update-application` | Status changes; chains research/prep |
| `company-research` | `/skill:company-research` | Role brief on shortlist |
| `resume-feedback` | `/skill:resume-feedback` | Resume vs JD review |
| `interview-prep` | `/skill:interview-prep` | Talking points on apply |

Load a skill explicitly with `/skill:name` if the model does not pick it up automatically.

## Local model notes

- LM Studio serves at `http://127.0.0.1:1234/v1` (OpenAI-compatible).
- Prefer `qwen/qwen3.5-9b` or `qwen/qwen2.5-coder-14b` for agent tasks.
- Web search and browser steps in skills may need [pi-skills](https://github.com/badlogic/pi-skills) (`pi install git:github.com/badlogic/pi-skills`) or manual curl/bash fallbacks.
- `iago-setup` uses conversational prompts; in Pi, ask questions in chat instead of `AskQuestion`.

## Scripts

```bash
bash scripts/verify-lm-studio.sh      # preflight
bash scripts/install-pi-skills.sh     # link skills for Pi
bash scripts/run-daily-search-pi.sh   # headless daily search
```
