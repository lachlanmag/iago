# Roadmap

Prioritized backlog for the job-search Cursor workflow. v1 search and triage skills (`job-search-daily`, `job-search-pipeline-review`) and v1.1 application workflow skills (`update-application`, `company-research`, `interview-prep`, `resume-feedback`) are shipped. Remaining items are tracked as [GitHub issues](https://github.com/lachlanmag/job-search/issues).

Issue numbers link to open tickets. Merged duplicates are noted inline.

## Skills

| Skill | Status | Issue | Purpose |
|-------|--------|-------|---------|
| `job-search-daily` | **Shipped** | n/a | Daily search, dedup, QA gate, fit scoring, tracker updates, daily report |
| `job-search-pipeline-review` | **Shipped** | n/a | Triage open pipeline, re-verify listings, rank and recommend shortlist/apply priorities |
| `job-search-setup` | Planned | [#1](https://github.com/lachlanmag/job-search/issues/1) | Conversational onboarding; writes gitignored `data/` YAML |
| `update-application` | **Shipped** | [#5](https://github.com/lachlanmag/job-search/issues/5) | Pipeline status updates; chains research on shortlist and prep on apply |
| `company-research` | **Shipped** | [#6](https://github.com/lachlanmag/job-search/issues/6) | Role brief from company site + JD (auto on shortlist) |
| `interview-prep` | **Shipped** | [#7](https://github.com/lachlanmag/job-search/issues/7) | Talking points from JD + resume (auto on apply) |
| `resume-feedback` | **Shipped** | n/a | Tailored resume review vs JD before submit |
| `recruiter-follow-up` | Planned | [#8](https://github.com/lachlanmag/job-search/issues/8) | Touchpoint logging aligned with `data/recruiters.yaml` |

---

## Now (v1.1)

Core onboarding and day-to-day tracker updates.

| # | Item | Issue | Notes |
|---|------|-------|-------|
| 1 | **Setup skill** | [#1](https://github.com/lachlanmag/job-search/issues/1) | Guided chat flow replaces hand-editing `config.yaml`. Includes launchd plist substitution ([#21](https://github.com/lachlanmag/job-search/issues/21)) as optional sub-task. |
| 2 | **Config validation** | [#14](https://github.com/lachlanmag/job-search/issues/14) | Health check script + YAML schema validation (merged from [#18](https://github.com/lachlanmag/job-search/issues/18)). Run after setup or before daily search. |
| 3 | ~~**Update-application skill**~~ | [#5](https://github.com/lachlanmag/job-search/issues/5) | Shipped with `company-research` + `interview-prep` chaining. |

---

## Next (v1.2)

Source catalog, regional presets, and onboarding docs.

| # | Item | Issue | Notes |
|---|------|-------|-------|
| 4 | **Default source catalog** | [#23](https://github.com/lachlanmag/job-search/issues/23) | Repo-maintained defaults by role/region; user add/exclude in gitignored config. Absorbs shared source lists ([#10](https://github.com/lachlanmag/job-search/issues/10)) and expand starter lists ([#20](https://github.com/lachlanmag/job-search/issues/20)). |
| 5 | **Regional config presets** | [#9](https://github.com/lachlanmag/job-search/issues/9) | AU metros, US, UK starters. Composes with #23 defaults + #1 setup. |
| 6 | **Example daily run in docs** | [#16](https://github.com/lachlanmag/job-search/issues/16) | Sanitized sample report; no real companies. |

---

## Later

Quality, secondary skills, integrations, and contributor docs.

| # | Item | Issue | Notes |
|---|------|-------|-------|
| 7 | **Configurable tier scoring** | [#22](https://github.com/lachlanmag/job-search/issues/22) | Move tier criteria from skill into `config.yaml`. |
| 8 | **Dedup/freshness test suite** | [#19](https://github.com/lachlanmag/job-search/issues/19) | Lock behavior for rules in skill + config. |
| 9 | ~~**Company-research skill**~~ | [#6](https://github.com/lachlanmag/job-search/issues/6) | Shipped. |
| 10 | ~~**Interview-prep skill**~~ | [#7](https://github.com/lachlanmag/job-search/issues/7) | Shipped. |
| 11 | **CSV export** | [#11](https://github.com/lachlanmag/job-search/issues/11) | One-off export of `applications.yaml`. |
| 12 | **Resume-Matcher hook docs** | [#3](https://github.com/lachlanmag/job-search/issues/3) | Shortlist → external tailoring handoff; document expected JSON shape for `resume-feedback`. |
| 13 | **Contributing guide** | [#15](https://github.com/lachlanmag/job-search/issues/15) | Needed before community PRs on source catalog (#23). |
| 14 | **Notification webhooks** | [#4](https://github.com/lachlanmag/job-search/issues/4) | Slack/email on daily run completion or top-pick changes. |
| 15 | **Launchd plist automation** | [#21](https://github.com/lachlanmag/job-search/issues/21) | Auto `__REPO_ROOT__` substitution; may land inside #1. |
| 16 | **Resume-feedback tracker integration** | n/a | `update-application` sets `resume_status: ready` when user confirms apply-ready after feedback. |

---

## Park / defer

Large scope, niche audience, or blocked on earlier work.

| Item | Issue | Notes |
|------|-------|-------|
| Obsidian compatibility layer | [#2](https://github.com/lachlanmag/job-search/issues/2) | v1 is repo-native only; personal data stays gitignored. |
| SQLite backend | [#12](https://github.com/lachlanmag/job-search/issues/12) | Only if YAML tracker outgrows flat files. |
| GitHub Action wrapper | [#13](https://github.com/lachlanmag/job-search/issues/13) | Self-hosted runner + Cursor CLI; advanced. |
| Public demo video | [#17](https://github.com/lachlanmag/job-search/issues/17) | Do after #1 + #23 so demo shows real happy path. |
| Recruiter-follow-up skill | [#8](https://github.com/lachlanmag/job-search/issues/8) | Unless actively using `recruiters.yaml`. |

---

## Merged issues

Closed as duplicates; work tracked on the parent issue.

| Closed | Merged into | Reason |
|--------|-------------|--------|
| [#10](https://github.com/lachlanmag/job-search/issues/10) Shared search source lists | [#23](https://github.com/lachlanmag/job-search/issues/23) | Defaults catalog + community contributions |
| [#20](https://github.com/lachlanmag/job-search/issues/20) Expand starter search source lists | [#23](https://github.com/lachlanmag/job-search/issues/23) | Seed data for defaults catalog |
| [#18](https://github.com/lachlanmag/job-search/issues/18) YAML schema validation | [#14](https://github.com/lachlanmag/job-search/issues/14) | Single config validation deliverable |

---

## How to propose additions

Open an issue or PR with:

1. Which backlog tier it fits (Now / Next / Later / Park)
2. Whether it needs personal data (must stay in `data/`, gitignored)
3. Whether it belongs in a skill, examples, or scripts
