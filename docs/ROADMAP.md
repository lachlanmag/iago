# Roadmap

Future work and known gaps for the job-search Cursor workflow. Nothing here is required for v1.

## Integrations

| Item | Notes |
|------|-------|
| **Obsidian compatibility layer** | Optional sync or vault layout for users who keep notes in Obsidian. v1 is repo-native only (`data/` YAML + markdown reports). |
| **Resume-Matcher hook** | Optional docs for wiring shortlist → external tailoring. Maintainer uses a Resume-Matcher fork; not part of this repo. |
| **Notification webhooks** | Slack/email when daily run completes or top picks change |

## Skills

| Skill | Purpose |
|-------|---------|
| `job-search-pipeline-review` | Triage open pipeline, re-verify listings, rank and recommend shortlist/apply priorities |
| `update-application` | Structured prompts to mark applied, rejected, interview stages |
| `company-research` | Pre-interview brief from company site + JD |
| `interview-prep` | Talking points from JD + local resume |
| `recruiter-follow-up` | Touchpoint logging aligned with `data/recruiters.yaml` |

## Config and data

| Item | Notes |
|------|-------|
| **Regional presets** | Example configs for AU metros, US, UK (community contributions) |
| **Shared source lists** | Curated board URLs by region and role family |
| **CSV export** | One-off export of `applications.yaml` for spreadsheets |
| **SQLite backend** | If YAML tracker outgrows flat files |

## Automation

| Item | Notes |
|------|-------|
| **GitHub Action wrapper** | Scheduled run via self-hosted runner + Cursor CLI (advanced) |
| **Health check script** | Validate config schema, resume path exists, tracker YAML parses |

## Publishing

| Item | Notes |
|------|-------|
| **Contributing guide** | How to submit source lists and regional configs |
| **Sanitized example daily run** | Sample `data/daily-runs/` output in docs (no real companies) |
| **Public demo video** | Walkthrough: init → configure → first search |

## Known gaps (v1)

- No schema validation on YAML files (agent + human review only)
- No built-in test suite for dedup/freshness rules
- Search source lists in `examples/config.example.yaml` are minimal starters
- macOS launchd plist requires manual `__REPO_ROOT__` substitution
- Tier scoring rules are documented in the skill but not configurable in YAML

## How to propose additions

Open an issue or PR with:

1. Which roadmap area it fits
2. Whether it needs personal data (must stay in `data/`, gitignored)
3. Whether it belongs in the skill, examples, or scripts
