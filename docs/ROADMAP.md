# Roadmap

Prioritized backlog for the Iago workflow (Cursor, Claude Code, and LM Studio). Remaining items are tracked as [GitHub issues](https://github.com/lachlanmag/iago/issues).

Issue numbers link to open tickets. Merged duplicates are noted inline.

## Shipped

What works today, grouped by area. Skills are listed in full below; other shipped work is summarized by category rather than one row per issue.

### Skills

Canonical workflow content lives in `skills/`. Platform entrypoints live under `.cursor/skills/`, `.claude/skills/`, and (in progress) `.lmstudio/skills/` ([#33](https://github.com/lachlanmag/iago/issues/33) / [PR #38](https://github.com/lachlanmag/iago/pull/38); LM Studio [#36](https://github.com/lachlanmag/iago/issues/36)).


| Skill                  | Status      | Issue                                             | Purpose                                                                                                          |
| ---------------------- | ----------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `iago-daily`           | **Shipped** | n/a                                               | Daily search, dedup, QA gate, fit scoring, tracker updates, daily report                                         |
| `iago-pipeline-review` | **Shipped** | n/a                                               | Triage open pipeline, re-verify listings, rank and recommend shortlist/apply priorities                          |
| `iago-setup`           | **Shipped** | [#1](https://github.com/lachlanmag/iago/issues/1) | Conversational onboarding; writes gitignored `data/` YAML ([PR #30](https://github.com/lachlanmag/iago/pull/30)) |
| `update-application`   | **Shipped** | [#5](https://github.com/lachlanmag/iago/issues/5) | Pipeline status updates; chains research on shortlist and prep on apply                                          |
| `company-research`     | **Shipped** | [#6](https://github.com/lachlanmag/iago/issues/6) | Role brief from company site + JD (auto on shortlist)                                                            |
| `interview-prep`       | **Shipped** | [#7](https://github.com/lachlanmag/iago/issues/7) | Talking points from JD + resume (auto on apply)                                                                  |
| `resume-feedback`      | **Shipped** | n/a                                               | Resume review vs JD before submit (markdown default; optional Resume-Matcher JSON)                               |
| `recruiter-follow-up`  | Planned     | [#8](https://github.com/lachlanmag/iago/issues/8) | Touchpoint logging aligned with `data/recruiters.yaml` (see Park)                                                |




### Platforms

Cursor and Claude Code run the same skill workflows via shared `skills/` plus thin wrappers ([#33](https://github.com/lachlanmag/iago/issues/33) / [PR #38](https://github.com/lachlanmag/iago/pull/38)). LM Studio interactive support (khtsly/skills + `.lmstudio/skills/`) is **in progress** on [#36](https://github.com/lachlanmag/iago/issues/36) / [PR #41](https://github.com/lachlanmag/iago/pull/41); move to Shipped after mid-bar smoke.

### Search quality

Daily QA pass refined for hidden-employer and aggregator-only listings so live roles are not dropped for missing direct employer links ([#28](https://github.com/lachlanmag/iago/issues/28) / [PR #29](https://github.com/lachlanmag/iago/pull/29)).

### Docs and onboarding

Non-contributor update path documented in README ([#31](https://github.com/lachlanmag/iago/issues/31) / [PR #32](https://github.com/lachlanmag/iago/pull/32)). Guided setup via `iago-setup` ([#1](https://github.com/lachlanmag/iago/issues/1) / [PR #30](https://github.com/lachlanmag/iago/pull/30)).

---



## Now

Active work only.


| # | Item | Issue | Notes |
|---|------|-------|-------|
| 1 | **LM Studio support (v1)** | [#36](https://github.com/lachlanmag/iago/issues/36) | **In progress** (`issue-36-lm-studio-support`): interactive skills in LM Studio chat via [khtsly/skills](https://lmstudio.ai/khtsly/skills). Pi/headless deferred to [#40](https://github.com/lachlanmag/iago/issues/40). |

---

## Next

Docs examples, config tooling, and additional local platforms after LM Studio v1.

| # | Item | Issue | Notes |
|---|------|-------|-------|
| 2 | **Config validation** | [#14](https://github.com/lachlanmag/iago/issues/14) | Health check script + YAML schema validation (merged from [#18](https://github.com/lachlanmag/iago/issues/18)). Run after setup or before daily search. |
| 3 | **Example daily run in docs** | [#16](https://github.com/lachlanmag/iago/issues/16) | Sanitized sample report; no real companies. |
| 4 | **Ollama / Open WebUI support** | [#37](https://github.com/lachlanmag/iago/issues/37) | Thin wrappers over shared `skills/` after #36 pattern is proven. Discovery notes in [#35](https://github.com/lachlanmag/iago/issues/35). |

---

## Later

Quality, integrations, and tracker polish.

| # | Item | Issue | Notes |
|---|------|-------|-------|
| 5 | **Configurable tier scoring** | [#22](https://github.com/lachlanmag/iago/issues/22) | Move tier criteria from skill into `config.yaml`. |
| 6 | **Dedup/freshness test suite** | [#19](https://github.com/lachlanmag/iago/issues/19) | Lock behavior for rules in skill + config. |
| 7 | **CSV export** | [#11](https://github.com/lachlanmag/iago/issues/11) | One-off export of `applications.yaml`. |
| 8 | **Resume-Matcher hook docs** | [#3](https://github.com/lachlanmag/iago/issues/3) | Shortlist → external tailoring handoff; document expected JSON shape for `resume-feedback`. |
| 9 | **Notification webhooks** | [#4](https://github.com/lachlanmag/iago/issues/4) | Slack/email on daily run completion or top-pick changes. |
| 10 | **Resume-feedback tracker integration** | n/a | `update-application` sets `resume_status: ready` when user confirms apply-ready after feedback. |

---

## Park / defer

Large scope, niche audience, or deferred for now.

| Item | Issue | Notes |
|------|-------|-------|
| Default source catalog | [#23](https://github.com/lachlanmag/iago/issues/23) | Repo-maintained defaults by role/region; absorbs [#10](https://github.com/lachlanmag/iago/issues/10) and [#20](https://github.com/lachlanmag/iago/issues/20). |
| Regional config presets | [#9](https://github.com/lachlanmag/iago/issues/9) | AU metros, US, UK starters; composes with #23 + setup. |
| Contributing guide | [#15](https://github.com/lachlanmag/iago/issues/15) | Useful before community PRs on source catalog (#23). |
| Claude Code headless / platform automation | [#34](https://github.com/lachlanmag/iago/issues/34) | Headless daily runner, README repositioning, CI follow-ups after #33. |
| LM Studio automation (Pi) | [#40](https://github.com/lachlanmag/iago/issues/40) | Headless/scheduled runs via Pi + LM Studio; after #36 v1 is stable. |
| Obsidian compatibility layer | [#2](https://github.com/lachlanmag/iago/issues/2) | v1 is repo-native only; personal data stays gitignored. |
| SQLite backend | [#12](https://github.com/lachlanmag/iago/issues/12) | Only if YAML tracker outgrows flat files. |
| GitHub Action wrapper | [#13](https://github.com/lachlanmag/iago/issues/13) | Self-hosted runner + Cursor CLI; advanced. |
| Public demo video | [#17](https://github.com/lachlanmag/iago/issues/17) | Do after setup + source catalog (#23) so demo shows real happy path. |
| Recruiter-follow-up skill | [#8](https://github.com/lachlanmag/iago/issues/8) | Unless actively using `recruiters.yaml`. |


---



## Merged issues

Closed as duplicates; work tracked on the parent issue.


| Closed                                                                                 | Merged into                                         | Reason                                     |
| -------------------------------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------ |
| [#10](https://github.com/lachlanmag/iago/issues/10) Shared search source lists         | [#23](https://github.com/lachlanmag/iago/issues/23) | Defaults catalog + community contributions |
| [#20](https://github.com/lachlanmag/iago/issues/20) Expand starter search source lists | [#23](https://github.com/lachlanmag/iago/issues/23) | Seed data for defaults catalog             |
| [#18](https://github.com/lachlanmag/iago/issues/18) YAML schema validation             | [#14](https://github.com/lachlanmag/iago/issues/14) | Single config validation deliverable       |


---



## How to propose additions

Open an issue or PR with:

1. Which backlog tier it fits (Now / Next / Later / Park)
2. Whether it needs personal data (must stay in `data/`, gitignored)
3. Whether it belongs in a skill, examples, or scripts

