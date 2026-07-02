# Job Search (Cursor workflow)

A Cursor-native workflow for sourcing PM/PO/BA roles and tracking applications. No app to deploy: open the repo in Cursor, configure local search criteria, and run a daily agent-driven search that updates YAML trackers and writes a daily report.

**In scope:** job search, deduplication, listing freshness checks, fit scoring, application pipeline tracking, pipeline triage and prioritization, role briefs on shortlist, resume feedback before apply, interview prep on submit.

**Out of scope:** resume tailoring or rewriting, cover letters, PDF export (`resume-feedback` reviews your resume against the JD; it does not rewrite it).

## Prerequisites

- [Cursor](https://cursor.com) with Agent
- Network access for job board search
- For headless runs: `cursor agent login` (once)

## Quick start

```bash
git clone git@github.com:lachlanmag/job-search.git
cd job-search
bash scripts/init-data.sh
```

1. Edit `data/config.yaml`:
   - Set `profile.resume_path` to your local master resume (markdown, outside this repo)
   - Set `profile.location`, role priorities, and search source URLs for your market
   - Optional: `profile.output_language` for research, prep, and feedback artifacts
2. Open the repo folder in Cursor
3. In chat: **Run the daily job search**

## Repository layout

```
job-search/
  .cursor/skills/
    job-search-daily/                # Daily search workflow
    job-search-pipeline-review/      # Pipeline triage and prioritization
    update-application/              # Status updates; chains research + prep
    company-research/                # Role brief (auto on shortlist)
    interview-prep/                  # Talking points (auto on apply)
    resume-feedback/                 # Resume review vs JD before submit
  examples/                          # Templates to copy into data/
  data/                              # Your local state (gitignored)
  scripts/                           # init-data.sh, reconcile-config.sh, run-daily-search.sh
  docs/ROADMAP.md                    # Future work and gaps
```

### Local data (`data/`)

Following the same pattern as [Resume-Matcher](https://github.com/srbhr/Resume-Matcher) (`apps/backend/data/`): personal files live in a gitignored directory inside the repo.

| File | Purpose |
|------|---------|
| `config.yaml` | Search criteria, sources, fit rubric |
| `applications.yaml` | Application pipeline tracker |
| `seen-jobs.yaml` | Dedup index |
| `recruiters.yaml` | Recruiter outreach (optional) |
| `daily-runs/YYYY-MM-DD.md` | Daily search reports |
| `pipeline-reviews/YYYY-MM-DD.md` | Pipeline triage and prioritization reports |
| `company-research/` | Role briefs (auto when shortlisted) |
| `jds/` | Full job descriptions (auto when shortlisted) |
| `interview-prep/` | Interview prep (auto when applied) |
| `resume-feedback/` | Resume feedback artifacts |
| `logs/` | CLI run logs |

Nothing under `data/` is committed. Run `git status` after a daily search or pipeline review to confirm.

## Running a daily search

**In Cursor chat:**

> Run the daily job search

**Headless (Cursor Agent CLI):**

```bash
bash scripts/run-daily-search.sh
```

Logs: `data/logs/latest.log`

**Optional: schedule on macOS (weekdays 8 AM)**

```bash
chmod +x scripts/*.sh
# Replace __REPO_ROOT__ in scripts/com.example.job-search-daily.plist with your clone path
cp scripts/com.example.job-search-daily.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.example.job-search-daily.plist
```

Override run timezone: `JOB_SEARCH_TZ=Australia/Sydney bash scripts/run-daily-search.sh`

## Reviewing your pipeline

After daily searches build up `discovered` roles, triage and prioritize without running a new search:

> Review my pipeline and tell me what to prioritize

Writes a report to `data/pipeline-reviews/YYYY-MM-DD.md` with ranked apply targets, shortlist promotions, and listing verification. Trigger phrases: pipeline review, prioritize applications, `/pipeline-review`.

## Apply workflow

Typical path from shortlist to interview prep:

```
# Standalone (default)
shortlist → company-research → resume-feedback → apply → interview-prep

# With Resume-Matcher (integrations.resume_matcher.enabled: true)
shortlist → company-research → tailor via Resume-Matcher → resume-feedback → apply → interview-prep
```

Point `profile.resume_path` at your master resume for fit scoring during search and for standalone resume feedback. Shortlisting via `update-application` or pipeline review saves the full JD to `data/jds/` and sets `jd_path` on the tracker row automatically.

If you initialized `data/` before v1.1, re-run `bash scripts/init-data.sh` to create `jds/`, `company-research/`, `interview-prep/`, and `resume-feedback/` (safe to re-run; existing config files are not overwritten).

When the example template gains new keys (e.g. `integrations.resume_matcher.enabled`), merge them into your existing `data/config.yaml` without overwriting your values:

```bash
bash scripts/reconcile-config.sh --dry-run   # preview keys to add
bash scripts/reconcile-config.sh             # apply (creates a timestamped .bak backup)
```

Requires `pip3 install ruamel.yaml` (preserves YAML comments).

### Updating applications

Use `update-application` so status changes chain follow-on work automatically:

| Action | Command example | Chained skill |
|--------|-----------------|---------------|
| Shortlist | `Shortlist [Company]` | `company-research` (saves JD + role brief) |
| Apply | `Set [Company] to applied on [date]` | `interview-prep` (talking points) |

Pipeline review also runs `company-research` when you confirm a `discovered` → `shortlisted` promotion.

Status values: `discovered`, `shortlisted`, `applied`, `interview`, `rejected`, `withdrawn`, `offer`, `closed`.

### Company research (on shortlist)

Produces a role brief under `data/company-research/`, saves the full JD under `data/jds/`, and sets `company_research` and `jd_path` on the tracker row.

> Research [Company] for this role

Trigger phrases: company brief, role brief, `/company-research`. Runs automatically when you shortlist via `update-application` or pipeline review.

### Resume feedback (before apply)

Reviews your resume against the job description. Does not rewrite the resume. Artifacts save to `data/resume-feedback/`.

**Standalone (default):** Reviews markdown from `profile.resume_path` (or an override path you provide) against the JD. No Resume-Matcher or JSON required.

**With Resume-Matcher:** Set `integrations.resume_matcher.enabled: true` in `data/config.yaml`, tailor via [Resume-Matcher](https://github.com/srbhr/Resume-Matcher), then provide the tailored JSON path (or inline JSON) for review.

> Review my resume for [Company]

For a shortlisted role, the JD comes from `jd_path` on the tracker row (or a path you provide). Trigger phrases: resume feedback, ATS review, `/resume-feedback`.

### Interview prep (on apply)

Produces talking points under `data/interview-prep/` and sets `interview_prep` on the tracker row.

> Interview prep for [Company]

Trigger phrases: talking points, `/interview-prep`. Runs automatically when you set status to `applied` via `update-application`.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for planned skills, Obsidian compatibility, regional presets, and other expansion ideas.

## License

MIT. See [LICENSE](LICENSE).
