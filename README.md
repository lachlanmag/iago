# Job Search (Cursor workflow)

A Cursor-native workflow for sourcing PM/PO/BA roles and tracking applications. No app to deploy: open the repo in Cursor, configure local search criteria, and run a daily agent-driven search that updates YAML trackers and writes a daily report.

**In scope:** job search, deduplication, listing freshness checks, fit scoring, application pipeline tracking, pipeline triage and prioritization.

**Out of scope:** resume tailoring, cover letters, PDF export (use any external tools you prefer after shortlisting).

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
2. Open the repo folder in Cursor
3. In chat: **Run the daily job search**

## Repository layout

```
job-search/
  .cursor/skills/
    job-search-daily/                # Daily search workflow
    job-search-pipeline-review/      # Pipeline triage and prioritization
  examples/                          # Templates to copy into data/
  data/                              # Your local state (gitignored)
  scripts/                           # init-data.sh, run-daily-search.sh
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

## Updating applications

After you apply, ask Cursor:

> Update data/applications.yaml — set [company] to applied on [date]

Or edit `data/applications.yaml` directly. Status values: `discovered`, `shortlisted`, `applied`, `interview`, `rejected`, `withdrawn`, `offer`, `closed`.

## Resume and tailoring

This repo does not handle resumes. Point `profile.resume_path` at your master resume for fit scoring during search. After shortlisting, save job descriptions and run your preferred tailoring workflow separately.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for planned skills, Obsidian compatibility, regional presets, and other expansion ideas.

## License

MIT — see [LICENSE](LICENSE).
