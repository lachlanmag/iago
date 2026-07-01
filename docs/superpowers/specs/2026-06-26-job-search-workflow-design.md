# Job Search Cursor Workflow: Design

## Goal

Publish a Cursor-native workflow for sourcing PM/PO/BA roles and tracking applications. Users clone the repo, copy sanitized templates into a gitignored `data/` directory, customize search criteria locally, and run a daily agent-driven search that updates tracker YAML and writes a daily report.

No personal data, tracker history, or resume content is committed to git.

## Scope

### In scope (v1)

- **`job-search-daily` skill**: search, dedup, listing freshness, QA gate, fit scoring, tracker updates, daily report
- **`examples/`**: sanitized templates for `config.yaml`, `applications.yaml`, `seen-jobs.yaml`, `recruiters.yaml`
- **Gitignored `data/`**: all live/personal state (Resume-Matcher pattern)
- **`scripts/run-daily-search.sh`**: headless daily run via Cursor Agent CLI
- **Optional macOS launchd plist template**: weekday scheduling
- **`README.md`**: clone, init data, configure, first run
- **`docs/ROADMAP.md`**: gaps, future work, Obsidian compatibility layer

### Out of scope (v1)

- Resume tailoring, cover letters, PDF export
- Obsidian integration (roadmap only)
- Web UI or database
- Personal search criteria, tracker rows, or daily run history in git

### Resume tooling (informational only)

Job sourcing and application tracking are independent of resume tooling. The maintainer optionally uses a public [Resume-Matcher](https://github.com/lachlanmag/Resume-Matcher) fork after shortlisting. That integration is not part of this repo and not required to use the workflow.

## Architecture

**Approach:** Single skill + flat repo (mirrors the maintainer's working Cursor workflow, adapted for publication).

```
job-search/
  .cursor/skills/job-search-daily/SKILL.md
  examples/
    config.example.yaml
    applications.example.yaml
    seen-jobs.example.yaml
    recruiters.example.yaml
  data/                    # gitignored except .gitkeep
    .gitkeep
  scripts/
    run-daily-search.sh
    init-data.sh           # copy examples → data/
    com.example.job-search-daily.plist
  docs/
    ROADMAP.md
  README.md
  .gitignore
```

### Tracked vs local data

| Path | Git | Purpose |
|------|-----|---------|
| `.cursor/skills/` | tracked | Agent workflow definitions |
| `examples/` | tracked | Sanitized templates and schema docs |
| `scripts/` | tracked | Automation helpers |
| `docs/` | tracked | Roadmap and superpowers specs/plans |
| `data/config.yaml` | **ignored** | User search criteria, sources, fit themes |
| `data/applications.yaml` | **ignored** | Application pipeline tracker |
| `data/seen-jobs.yaml` | **ignored** | Dedup index |
| `data/recruiters.yaml` | **ignored** | Recruiter outreach tracker |
| `data/daily-runs/` | **ignored** | Daily run reports |
| `data/logs/` | **ignored** | CLI run logs |

**Setup flow:**

1. Clone repo and open in Cursor.
2. Run `scripts/init-data.sh` (or manually copy `examples/*` → `data/`).
3. Edit `data/config.yaml` with location, role priorities, sources, and `profile.resume_path`.
4. Point `profile.resume_path` at a local markdown resume (outside repo or gitignored).
5. Run daily search via chat or `bash scripts/run-daily-search.sh`.

**`.gitignore` pattern** (same idea as Resume-Matcher `apps/backend/data/`):

```
data/*
!data/.gitkeep
```

## Data model

### `config.yaml`

Search criteria distilled from the maintainer's working config:

- `profile`: `resume_path`, location, relocation preference
- `role_priority`: ordered role titles
- `location_rules`: local vs remote rules
- `preferences`: industry, work model, seniority
- `industry_labels`: standard labels for tracker rows
- `industry_awareness`: ★ actively targeting, ⚠ prefer to avoid (flag only, never filter)
- `resume_fit`: scoring rubric against local resume
- `deduplication`: match rules, normalization, canonical URL priority
- `listing_freshness`: closed signals, closing dates, open proof, board hints
- `qa_gate`: mandatory checks before any tracker write
- `search_sources`: ordered source list with URLs
- `excluded_sources`: boards to skip
- `watch_companies`: company ATS watch list

The published `examples/config.example.yaml` uses generic placeholders (city, region, sample URLs) rather than personal criteria.

### `applications.yaml`

Pipeline tracker. Status values:

`discovered | shortlisted | applied | interview | rejected | withdrawn | offer | closed`

Optional fields: `industry`, `resume_fit`, `resume_fit_note`, `channel`, `recruiter_id`, `resume_status`, `closes` (in notes).

### `seen-jobs.yaml`

Dedup index: canonical URL, company, title, `first_seen`, optional `alternate_urls`, `ats_id`, `listing_verified`.

### `recruiters.yaml`

Recruiter outreach tracker with touchpoint history.

## Workflow behavior

Port the maintainer's `job-search-daily` skill with these adaptations:

1. **Paths**: all reads/writes use `data/` at repo root (no Obsidian vault paths).
2. **Profile**: `config.yaml` → `profile.resume_path` for fit scoring (local file only).
3. **No resume tooling in-repo**: after shortlisting, skill suggests saving the JD to a user-chosen path; no in-repo tailoring step.
4. **Timezone**: script defaults to `Australia/Brisbane`; override via `JOB_SEARCH_TZ`.
5. **Core loop unchanged:**
   - Load state
   - Search sources in `search_sources.order` (skip `excluded_sources`)
   - Listing freshness at intake (every candidate)
   - Dedup (canonical URL only)
   - Score and tier
   - Mandatory QA gate before any tracker write
   - Write daily report
   - Append QA-passing new roles to tracker files
6. **Flags**: industry ★/⚠ and resume fit ✓/~ are independent.

### Daily report layout

`data/daily-runs/YYYY-MM-DD.md`:

**Above the fold:** Summary, new roles, pipeline counts, shortlist, open tracker, flags summary, closed since last run.

**Below the fold:** Skipped expired, closing soon, QA gate, deduped, sources checked.

### Automation options (documented, optional)

- Chat: "Run the daily job search"
- Script: `bash scripts/run-daily-search.sh`
- Cursor `/loop` or macOS launchd plist

## Roadmap (`docs/ROADMAP.md`)

Structured backlog for v1+. Shipped since initial release: `update-application`, `company-research`, `interview-prep`, `resume-feedback` (see [apply workflow](../../../README.md#apply-workflow) in README). Design specs: [update-application](2026-07-01-update-application-design.md), [company-research](2026-07-01-company-research-design.md), [interview-prep](2026-07-01-interview-prep-design.md), [resume-feedback](2026-07-01-resume-feedback-design.md).

| Area | Examples |
|------|----------|
| **Integrations** | Obsidian vault sync layer; Resume-Matcher hook docs ([#3](https://github.com/lachlanmag/job-search/issues/3)) |
| **Skills** | `job-search-setup`, `recruiter-follow-up` |
| **Config** | Multi-region presets; community source lists |
| **Automation** | GitHub Action wrapper; notification webhooks |
| **Data** | CSV export; SQLite if YAML outgrows flat files |
| **Publishing** | Contributing guide; sanitized example daily run |

## Testing and validation

- **Manual:** Run init script, verify `data/` populated and gitignored; run skill once with empty tracker; confirm daily report path and no git changes under `data/`.
- **Sanitization:** Examples contain no personal names, companies applied to, or real tracker rows.
- **Path audit:** Skill and scripts contain no hardcoded maintainer paths.

## Success criteria

1. A new user can clone, init `data/`, configure, and run a daily search without Obsidian.
2. `git status` shows no personal data after a full daily run.
3. Workflow behavior matches the maintainer's existing daily search loop (search → dedup → QA → report → tracker).
4. `docs/ROADMAP.md` captures Obsidian layer and other expansion opportunities.
