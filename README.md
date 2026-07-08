

# Iago

**Iago is your job search assistant.** It's eager to help, full of opinions, and occasionally a little too sure of itself. Use it to surface roles, triage your pipeline, and prep for interviews, but treat its output as a starting point: check listings are still live, read the briefs, and sanity-check anything that sounds too good before you hit apply.

A Cursor-native workflow for sourcing PM/PO/BA roles and tracking applications. No app to deploy: open the repo in Cursor, configure local search criteria, and run a daily agent-driven search that updates YAML trackers and writes a daily report.

## Getting Started

```bash
cd ~/git-repos
git clone git@github.com:lachlanmag/iago.git job-search
cd job-search
bash scripts/init-data.sh   # optional; iago-setup runs this if data/ is missing
```

Clone into an existing empty folder with `git clone git@github.com:lachlanmag/iago.git .` (avoids a nested `iago/` directory).

**Recommended:** open the repo root in Cursor (the folder that contains `.cursor/skills/`) and run guided setup:

> Set up job search

Trigger phrases: set up job search, configure job search, job search onboarding, `/iago-setup`.

The setup skill collects your location, role priorities, resume path, search boards, and watch list, then writes `data/config.yaml` for you.

**Manual alternative:** edit `data/config.yaml` directly:

- Set `profile.resume_path` to your local master resume (markdown, outside this repo)
- Set `profile.location`, role priorities, and search source URLs for your market
- Optional: `profile.output_language` for research, prep, and feedback artifacts

Then in chat: **Run the daily job search**

### Prerequisites

- [Cursor](https://cursor.com) with Agent
- Network access for job board search
- For headless runs: `cursor agent login` (once)



### Cursor skills

Iago skills ship in `.cursor/skills/`. Cursor discovers them automatically when this repo is the workspace root.

If you use a **parent workspace** (e.g. Obsidian vault + several git repos), skills may be scoped to the Iago folder only. Two options:

1. **Open the Iago repo root** in Cursor (File → Open Folder).
2. **Symlink skills globally** (recommended for combined workspaces). Run from your Iago clone (scripts resolve paths from their own location):

```bash
cd /path/to/your/iago-clone
bash scripts/install-skills.sh
# Cmd+Shift+P → Developer: Reload Window
```

Check layout: `bash /path/to/your/iago-clone/scripts/verify-workspace.sh` (or `cd` into the clone first). The `iago-setup` skill runs these checks during onboarding and uses `$REPO_ROOT` for all paths when the workspace root is a parent folder.

## Updating Iago

Iago improves over time: new skills, bug fixes, and config options land on GitHub. You do **not** need to understand git deeply to stay current. You only need to download those updates into your local copy.

**Your job search data is safe.** Everything personal (tracker, config, reports) lives in `data/`, which is gitignored. Updating Iago refreshes code and skills only. It does not overwrite `data/`.

### When to update

Update when you want the latest Iago release, or when something in chat mentions a skill or script you do not seem to have yet. There is no fixed schedule. With a GitHub account, click **Watch** on the repo and choose **Releases only** to get notified when a new version lands. Without an account, check the [Releases](https://github.com/lachlanmag/iago/releases) page or run `git pull` occasionally.

### Steps (typical single-folder setup)

Open a terminal in your Iago folder (the directory that contains `.cursor/` and `scripts/`), then:

```bash
git pull
```

That fetches improvements from GitHub into your copy. If git asks you to commit or stash local changes first, you have probably edited tracked files (not `data/`). Ask in Cursor chat or open an issue if you are unsure.

**Merge new config keys** when the example template has gained options you might want (for example Resume-Matcher integration). This adds missing keys to your existing `data/config.yaml` without overwriting your values:

```bash
bash scripts/reconcile-config.sh --dry-run   # preview only
bash scripts/reconcile-config.sh             # apply (creates a timestamped backup)
```

Requires `pip3 install ruamel.yaml` once (preserves YAML comments).

**Reload Cursor** so updated skills are picked up: Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows/Linux) → **Developer: Reload Window**.

If your Cursor workspace is a **parent folder** (for example an Obsidian vault that contains Iago as a subfolder), also run:

```bash
bash scripts/install-skills.sh
```

Then reload the window again.

### What you do not need to do

- Re-clone the repo or run setup again unless you want a fresh start
- Copy files manually from GitHub
- Worry about `data/` being committed or deleted by `git pull`

If you use a more advanced layout (separate dev and production folders), see [Advanced: dev + prod worktrees](#advanced-dev--prod-worktrees) below. The steps above are for the common case: one Iago folder for daily job search.

### Advanced: dev + prod worktrees

**Contributors and power users only.** Skip this if you have a single Iago folder.

Some layouts use [git worktrees](https://git-scm.com/docs/git-worktree): one checkout for daily job search with real `data/` (prod, usually on `main`), and another for developing skills or scripts (dev, on feature branches). Code syncs via git; `data/` stays local to each checkout.

Typical pattern:

```
~/git-repos/iago-dev/          # primary clone (git home) — feature branches
~/path/to/iago-prod/           # worktree on main — real data/
```

Create a prod worktree from your dev clone (once):

```bash
cd /path/to/iago-dev
git fetch origin
git worktree add /path/to/iago-prod main
```

Develop on a feature branch in the dev clone, open a PR, and merge to `main`. Then update prod without touching its `data/`:

```bash
cd /path/to/iago-dev
bash scripts/sync-prod.sh
```

The script finds the other worktree on `main` automatically. If you have several worktrees, set the prod path explicitly:

```bash
IAGO_PROD_ROOT=/path/to/iago-prod bash scripts/sync-prod.sh
```

`sync-prod.sh` fast-forwards prod to `origin/main`, runs `reconcile-config.sh` in prod, and refreshes skill symlinks via `install-skills.sh`. It never modifies prod `data/`.

Preview config keys only: `bash scripts/sync-prod.sh --dry-run`

## How It Works

1. **Search for roles** with the daily search workflow.
2. **Track what you find** in local YAML files under `data/`.
3. **Review and prioritize** your pipeline when enough roles pile up.
4. **Shortlist and research** promising jobs, saving the JD and a brief automatically.
5. **Review your resume** before applying.
6. **Generate interview prep** once an application is submitted.



### What Iago handles

- Guided first-time setup (`iago-setup`)
- Daily job search and deduplication
- Listing freshness checks
- Fit scoring and prioritization
- Application pipeline tracking
- Company research on shortlist
- Resume feedback before apply
- Interview prep on submit



### What Iago does not handle

- Resume tailoring or rewriting
- Cover letter generation
- PDF export
- Final judgment on whether a role is worth applying to



## Core Workflows



### Daily search

**In Cursor chat:**

> Run the daily job search

Trigger phrases: daily job search, job hunt, find new jobs, `/iago`, `/iago-daily`.

**Headless (Cursor Agent CLI):**

```bash
bash scripts/run-daily-search.sh
```

Logs: `data/logs/latest.log`

Override run timezone: `IAGO_TZ=Australia/Sydney bash scripts/run-daily-search.sh`

### Pipeline review

After daily searches build up `discovered` roles, triage and prioritize without running a new search:

> Review my pipeline and tell me what to prioritize

Writes a report to `data/pipeline-reviews/YYYY-MM-DD.md` with ranked apply targets, shortlist promotions, and listing verification. Trigger phrases: pipeline review, prioritize applications, `/iago-pipeline`, `/pipeline-review`.

### Application workflow

Typical path from shortlist to interview prep:

```
# Standalone (default)
shortlist → company-research → resume-feedback → apply → interview-prep

# With Resume-Matcher (integrations.resume_matcher.enabled: true)
shortlist → company-research → tailor via Resume-Matcher → resume-feedback → apply → interview-prep
```

Point `profile.resume_path` at your master resume for fit scoring during search and for standalone resume feedback. Shortlisting via `update-application` or pipeline review saves the full JD to `data/jds/` and sets `jd_path` on the tracker row automatically.

If you initialized `data/` before v1.1, re-run `bash scripts/init-data.sh` to create `jds/`, `company-research/`, `interview-prep/`, and `resume-feedback/` (safe to re-run; existing config files are not overwritten).

When the example template gains new keys, merge them into your existing `data/config.yaml` without overwriting your values. See [Updating Iago](#updating-iago) for the full update flow; quick version:

```bash
bash scripts/reconcile-config.sh --dry-run   # preview keys to add
bash scripts/reconcile-config.sh             # apply (creates a timestamped .bak backup)
```



### Status updates

Use `update-application` so status changes chain follow-on work automatically:


| Action    | Command example                      | Chained skill                              |
| --------- | ------------------------------------ | ------------------------------------------ |
| Shortlist | `Shortlist [Company]`                | `company-research` (saves JD + role brief) |
| Apply     | `Set [Company] to applied on [date]` | `interview-prep` (talking points)          |


Pipeline review also runs `company-research` when you confirm a `discovered` -> `shortlisted` promotion.

Status values: `discovered`, `shortlisted`, `applied`, `interview`, `rejected`, `withdrawn`, `offer`, `closed`.

Trigger phrases: shortlist [Company], set [Company] to applied, update my tracker, `/iago-update`, `/update-application`.

### Company research

Produces a role brief under `data/company-research/`, saves the full JD under `data/jds/`, and sets `company_research` and `jd_path` on the tracker row.

> Research [Company] for this role

Trigger phrases: company brief, role brief, `/iago-brief`, `/company-research`. Runs automatically when you shortlist via `update-application` or pipeline review.

### Resume feedback

Reviews your resume against the job description. Does not rewrite the resume. Artifacts save to `data/resume-feedback/`.

**Standalone (default):** Reviews markdown from `profile.resume_path` (or an override path you provide) against the JD. No Resume-Matcher or JSON required.

**With Resume-Matcher:** Set `integrations.resume_matcher.enabled: true` in `data/config.yaml`, tailor via [Resume-Matcher](https://github.com/srbhr/Resume-Matcher), then provide the tailored JSON path (or inline JSON) for review.

> Review my resume for [Company]

For a shortlisted role, the JD comes from `jd_path` on the tracker row (or a path you provide). Trigger phrases: resume feedback, ATS review, `/iago-feedback`, `/resume-feedback`.

### Interview prep

Produces talking points under `data/interview-prep/` and sets `interview_prep` on the tracker row.

> Interview prep for [Company]

Trigger phrases: talking points, `/iago-interview`, `/interview-prep`. Runs automatically when you set status to `applied` via `update-application`.

## Repository Layout

```
iago/
  .cursor/skills/
    iago-daily/                    # Daily search; /iago, /iago-daily
    iago-setup/                    # Onboarding; /iago-setup
    iago-pipeline-review/          # Pipeline triage; /iago-pipeline
    update-application/            # Tracker updates; /iago-update
    company-research/              # Role brief; /iago-brief
    interview-prep/                # Talking points; /iago-interview
    resume-feedback/               # Resume review; /iago-feedback
  assets/                            # Logo and favicon
  examples/                          # Templates to copy into data/
  data/                              # Your local state (gitignored)
  scripts/                           # init-data.sh, install-skills.sh, verify-workspace.sh, reconcile-config.sh, run-daily-search.sh, sync-prod.sh (worktrees)
  favicon.ico                        # Browser favicon (16/32/48)
  favicon.png                        # Favicon PNG (32×32)
  docs/ROADMAP.md                    # Future work and gaps
```



### Local data

Following the same pattern as [Resume-Matcher](https://github.com/srbhr/Resume-Matcher) (`apps/backend/data/`): personal files live in a gitignored directory inside the repo.


| File                             | Purpose                                       |
| -------------------------------- | --------------------------------------------- |
| `config.yaml`                    | Search criteria, sources, fit rubric          |
| `applications.yaml`              | Application pipeline tracker                  |
| `seen-jobs.yaml`                 | Dedup index                                   |
| `recruiters.yaml`                | Recruiter outreach (optional)                 |
| `daily-runs/YYYY-MM-DD.md`       | Daily search reports                          |
| `pipeline-reviews/YYYY-MM-DD.md` | Pipeline triage and prioritization reports    |
| `company-research/`              | Role briefs (auto when shortlisted)           |
| `jds/`                           | Full job descriptions (auto when shortlisted) |
| `interview-prep/`                | Interview prep (auto when applied)            |
| `resume-feedback/`               | Resume feedback artifacts                     |
| `logs/`                          | CLI run logs                                  |


Nothing under `data/` is committed. Run `git status` after a daily search or pipeline review to confirm.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for planned skills, Obsidian compatibility, regional presets, and other expansion ideas.

## License

MIT. See [LICENSE](LICENSE).