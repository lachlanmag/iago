# Iago

**Iago is your personal job search henchman.** It's eager to help, full of opinions, and occasionally a little too sure of itself. Use it to surface roles, triage your pipeline, and prep for interviews, but treat its output as a starting point: check listings are still live, read the briefs, and sanity-check anything that sounds too good before you hit apply.

A Cursor-native workflow for sourcing tech roles and tracking applications. Right now it is built around my Product Management search, though the setup skill and config can adapt to other roles. No app to deploy: clone the repo, open it in Cursor, run setup in chat, and kick off a daily agent-driven search that updates YAML trackers and writes a daily report.

## Getting Started

### Prerequisites

- [Cursor](https://cursor.com) with Agent, or [Claude Code](https://docs.anthropic.com/en/docs/claude-code) as an optional alternative
- Network access for job board search
- For headless runs: `cursor agent login` (once)

### 1. Clone

```bash
# Use whatever folder you keep git repos in (e.g. ~/projects, ~/src, ~/code)
cd ~/projects
git clone git@github.com:lachlanmag/iago.git
cd iago
```

### 2. Run setup in Cursor

Open the repo root in Cursor (the folder that contains `.cursor/skills/`) and start guided setup in chat:

> Set up job search

Trigger phrases: set up job search, configure job search, job search onboarding, `/iago-setup`.

The setup skill initializes `data/` if needed, then walks you through location, role priorities, resume path, search boards, and watch list, and writes `data/config.yaml`.

### 3. Run your first search

> Run the daily job search

**Manual alternative:** run `bash scripts/init-data.sh`, then edit `data/config.yaml` directly (`profile.resume_path`, `profile.location`, role priorities, search sources). Optional: `profile.output_language` for research, prep, and feedback artifacts.



### Cursor skills

Iago skills ship in `.cursor/skills/`; canonical workflow content lives in `skills/` at the repo root (shared with Claude Code). Cursor discovers them automatically when this repo is the workspace root.

If your workspace is a **parent folder** (e.g. Obsidian vault + several git repos), there is no settings toggle for a custom skills path. Use one of these instead:

1. **Open the Iago repo root** (File → Open Folder). Simplest.
2. **Add Iago to the workspace** (File → Add Folder to Workspace). Skills in `iago/.cursor/skills/` are discovered when you work with files inside the Iago folder.
3. **Install skills globally** only if you need them everywhere in a large parent workspace without opening Iago files: `bash scripts/install-skills.sh` from your clone, then reload the window.

Check discovery in **Cursor Settings → Customize → Skills**. Layout check: `bash scripts/verify-workspace.sh` from your clone. The `iago-setup` skill runs these checks during onboarding and uses `$REPO_ROOT` for all paths when the workspace root is a parent folder.

## Upgrading Iago

Iago improves over time: new skills, bug fixes, and config options land on GitHub. You do **not** need to understand git or run scripts yourself.

**Your job search data is safe.** Everything personal (tracker, config, reports) lives in `data/`, which is gitignored. Upgrading Iago refreshes code and skills only. It does not overwrite your existing config values.

### When to upgrade

Upgrade when you want the latest Iago release, or when something in chat mentions a skill or script you do not seem to have yet. There is no fixed schedule. With a GitHub account, click **Watch** on the repo and choose **Releases only** to get notified when a new version lands.

### In Cursor chat (recommended)

> Upgrade Iago version

Trigger phrases: upgrade Iago version, upgrade version, get latest Iago, check for Iago updates, `/iago-upgrade-version`.

The `iago-upgrade-version` skill pulls from GitHub, merges any new config template keys into your `data/config.yaml`, refreshes global skill symlinks when your workspace is a parent folder, and reminds you to reload Cursor.

After a successful upgrade: **Developer: Reload Window** (Cmd+Shift+P on Mac, Ctrl+Shift+P on Windows/Linux).

### Manual alternative

Open a terminal in your Iago folder (the directory that contains `.cursor/` and `scripts/`), then:

```bash
bash scripts/upgrade-iago-version.sh           # full version upgrade
bash scripts/upgrade-iago-version.sh --check   # see if a newer version is available
bash scripts/upgrade-iago-version.sh --dry-run # preview new config keys only
```

Requires `pip3 install ruamel.yaml` once if config merge fails (preserves YAML comments).

### What you do not need to do

- Re-clone the repo or run setup again unless you want a fresh start
- Copy files manually from GitHub
- Worry about `data/` being committed or deleted by `git pull`

### Maintainer note

Optional solo-maintainer layout: **dev clone** (feature branches) + **daily-driver checkout** on `main` (real `data/`). Iago has no deploy target; version upgrade on the daily driver is `git pull` plus Iago-specific steps bundled in `sync-daily-driver.sh`.

From the dev clone after merging to `main`:

```bash
bash scripts/sync-daily-driver.sh              # refresh daily driver: pull main, reconcile-config, install-skills; never touches data/
bash scripts/sync-daily-driver.sh --dry-run    # preview new config keys only
IAGO_DAILY_DRIVER_ROOT=/path/to/daily-driver bash scripts/sync-daily-driver.sh   # if auto-detect fails
```

One-time daily-driver checkout: `git worktree add /path/to/iago-daily main` from the dev clone (a second full clone works too). Future contributors only need fork + PR on one clone.

### Claude Code skills

Skills install to `.claude/skills/`; canonical workflow content lives in `skills/` at the repo root. Open the repo root as your workspace.

For a **parent workspace** (e.g. Obsidian vault + several git repos), install from the Iago clone:

```bash
cd /path/to/your/iago-clone
bash scripts/install-skills.sh --platform claude
# or: bash scripts/install-skills.sh --platform both
```

Same chat triggers as Cursor (e.g. "Run the daily job search", "Set up job search", `/iago-daily`).

## How It Works

1. **Search for roles** with the daily search workflow.
2. **Track what you find** in local YAML files under `data/`.
3. **Review and prioritize** your pipeline when enough roles pile up.
4. **Shortlist and research** promising jobs, saving the JD and a brief automatically.
5. **Review your resume** before applying.
6. **Generate interview prep** once an application is submitted.



### What Iago handles

- Guided first-time setup (`iago-setup`)
- One-chat version upgrade (`iago-upgrade-version`)
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

### Upgrade Iago version

> Upgrade Iago version

Trigger phrases: upgrade Iago version, upgrade version, get latest Iago, `/iago-upgrade-version`.

### Daily search

**In Cursor chat:**

> Run the daily job search

Trigger phrases: daily job search, job hunt, find new jobs, `/iago`, `/iago-daily`.

**Headless (Cursor Agent CLI):**

Headless daily search requires the [Cursor Agent CLI](https://cursor.com/docs/agent/cli). Claude Code headless support is tracked in [#34](https://github.com/lachlanmag/iago/issues/34).

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

When the example template gains new keys, merge them into your existing `data/config.yaml` without overwriting your values. See [Upgrading Iago](#upgrading-iago) for the full flow; quick version:

```bash
bash scripts/upgrade-iago-version.sh --dry-run   # preview keys to add
bash scripts/upgrade-iago-version.sh             # pull + merge new keys
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
  skills/                            # Canonical workflow content (shared by both platforms)
    iago-daily/
    iago-setup/
    iago-pipeline-review/
    update-application/
    company-research/
    interview-prep/
    resume-feedback/
  .cursor/skills/                    # Cursor skill entrypoints (symlinked or copied from skills/)
    iago-daily/                    # Daily search; /iago, /iago-daily
    iago-setup/                    # Onboarding; /iago-setup
    iago-upgrade-version/          # Version upgrade; /iago-upgrade-version
    iago-pipeline-review/          # Pipeline triage; /iago-pipeline
    update-application/            # Tracker updates; /iago-update, /update-application
    company-research/              # Role brief; /iago-brief
    interview-prep/                # Talking points; /iago-interview
    resume-feedback/               # Resume review; /iago-feedback
  .claude/skills/                    # Claude Code skill entrypoints (symlinked or copied from skills/)
    iago-daily/
    iago-setup/
    iago-pipeline-review/
    update-application/
    company-research/
    interview-prep/
    resume-feedback/
  assets/                            # Logo and favicon
  examples/                          # Templates to copy into data/
  data/                              # Your local state (gitignored)
  scripts/                           # init-data.sh, install-skills.sh, verify-workspace.sh, reconcile-config.sh, upgrade-iago-version.sh, run-daily-search.sh, sync-daily-driver.sh (maintainer)
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