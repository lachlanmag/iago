# Iago Rebrand: Design

## Goal

Rename the product from **Job Search (Cursor workflow)** to **Iago**: a full rebrand across repo identity, user-facing copy, skill directories, slash commands, automation, and cross-references. The user is the sole operator; a single clean cut is preferred over compatibility shims.

Natural language triggers remain **activity-based** (e.g. "run the job search for today"). Slash commands use **Iago-branded** names, with legacy descriptive aliases retained.

## Scope

### In scope

- GitHub repo rename target: `lachlanmag/iago` (manual step on GitHub; in-repo URLs updated)
- Display title: **Iago**
- Doc tree root: `job-search/` → `iago/`
- Skill directory renames:
  - `job-search-daily/` → `iago-daily/`
  - `job-search-pipeline-review/` → `iago-pipeline-review/`
- Skill `name:` fields updated to match new directory names
- Slash commands: Iago-primary with descriptive aliases (see Trigger model)
- Natural language triggers: explicit lists in every skill `description` and "When to use"
- Env var: `JOB_SEARCH_TZ` → `IAGO_TZ`
- Launchd: `com.example.job-search-daily` → `com.example.iago-daily` (plist filename and label)
- `scripts/run-daily-search.sh`: skill path and env var
- README, ROADMAP, all existing design specs, all six skill SKILL.md files
- ROADMAP planned skill `job-search-setup` → `iago-setup`
- Post-merge checklist for out-of-repo steps (remote URL, local folder, launchd reload)

### Out of scope

- Renaming GitHub on github.com (documented manual step)
- Cursor user-level skill cache paths (updates when workspace folder is reopened)
- `data/` contents (gitignored; no product name refs)
- LICENSE copyright holder line
- Git history

### Unchanged skill folders

These describe function, not the old product name:

- `update-application/`
- `company-research/`
- `interview-prep/`
- `resume-feedback/`

## Approach

**Single-pass rebrand (recommended):** one PR on `rename-app` with all in-repo changes. GitHub rename, local clone path, and launchd reload are manual follow-ups documented in Post-merge checklist.

Rejected alternatives:

- **Two-phase** (in-repo then infra): leaves remote URL and local path stale between phases.
- **Compatibility shim** (symlinks, duplicate paths): contradicts full rebrand for a solo user.

## Naming map

| Current | New |
|---------|-----|
| GitHub `lachlanmag/job-search` | `lachlanmag/iago` |
| Display title "Job Search (Cursor workflow)" | **Iago** |
| Doc tree root `job-search/` | `iago/` |
| `.cursor/skills/job-search-daily/` | `iago-daily/` |
| `.cursor/skills/job-search-pipeline-review/` | `iago-pipeline-review/` |
| Skill `name: job-search-daily` | `iago-daily` |
| Skill `name: job-search-pipeline-review` | `iago-pipeline-review` |
| `/job-search` | `/iago`, `/iago-daily` |
| `JOB_SEARCH_TZ` | `IAGO_TZ` |
| `com.example.job-search-daily` | `com.example.iago-daily` |
| `scripts/com.example.job-search-daily.plist` | `scripts/com.example.iago-daily.plist` |
| ROADMAP `job-search-setup` | `iago-setup` |

## Trigger model

**Slash commands** = Iago-branded primary; legacy descriptive aliases retained.

**Natural language** = activity-based phrases; user does not need to say "Iago" in chat.

Each skill's YAML `description` and "When to use" section must list both slash and natural language triggers explicitly.

### `iago-daily` (daily search)

| Type | Triggers |
|------|----------|
| Slash | `/iago`, `/iago-daily` |
| Natural language | "daily job search", "job hunt", "find new jobs", "run the job search", "run the job search for today", "check for jobs today", "search for new PM roles", "what's new on the boards", "update the tracker from today's search" |

**Disambiguation:** Remove generic "update applications" from this skill. Status changes (shortlist, applied, rejected) belong to `update-application`. Daily search adds new `discovered` rows from boards; it does not change pipeline status.

### `iago-pipeline-review` (pipeline triage)

| Type | Triggers |
|------|----------|
| Slash | `/iago-pipeline`, `/pipeline-review` (alias) |
| Natural language | "review my pipeline", "prioritize applications", "triage discovered roles", "what should I apply to first", "which jobs should I shortlist", "rank my open roles", "weekly pipeline review", "help me decide what to apply to this week" |

### `update-application` (tracker status)

| Type | Triggers |
|------|----------|
| Slash | `/iago-update`, `/update-application` (alias) |
| Natural language | "shortlist [Company]", "set [Company] to applied", "mark [Company] as rejected", "withdraw [Company]", "move [Company] to interview", "update my tracker", "I applied to [Company]", "reject [Company]" |

**Automatic chaining:** `shortlisted` → `company-research`; `applied` → `interview-prep`.

### `company-research` (role brief)

| Type | Triggers |
|------|----------|
| Slash | `/iago-brief`, `/company-research` (alias) |
| Natural language | "research [Company]", "company brief for [Company]", "role brief for [Company]", "brief on this role", "tell me about [Company] for this role", "prep a brief before I apply" |

**Automatic:** runs when a role is promoted to `shortlisted`.

### `interview-prep` (talking points)

| Type | Triggers |
|------|----------|
| Slash | `/iago-interview`, `/interview-prep` (alias) |
| Natural language | "interview prep for [Company]", "talking points for [role]", "help me prep for [Company] interview", "STAR stories for [Company]", "questions to ask [Company]" |

**Automatic:** runs when status moves to `applied`.

### `resume-feedback` (tailored resume review)

| Type | Triggers |
|------|----------|
| Slash | `/iago-feedback`, `/resume-feedback` (alias) |
| Natural language | "resume feedback", "review my tailored resume", "ATS review for [Company]", "check my resume against the JD", "tailoring quality check", "is this resume ready to submit" |

### Slash command summary

| Skill | Primary slash | Alias |
|-------|---------------|-------|
| Daily search | `/iago`, `/iago-daily` | — |
| Pipeline review | `/iago-pipeline` | `/pipeline-review` |
| Tracker updates | `/iago-update` | `/update-application` |
| Company brief | `/iago-brief` | `/company-research` |
| Interview prep | `/iago-interview` | `/interview-prep` |
| Resume review | `/iago-feedback` | `/resume-feedback` |

## User-facing copy

- README title: `# Iago` with subtitle explaining Cursor workflow for PM/PO/BA job search
- Activity headings may stay descriptive ("Daily job search", "Pipeline review") since they describe what the user is doing
- Quick start natural language: "Run the daily job search" (no "Iago" required)
- Clone instructions: `git clone git@github.com:lachlanmag/iago.git` and `cd iago`

## Files to change

### Directory renames

1. `.cursor/skills/job-search-daily/` → `iago-daily/`
2. `.cursor/skills/job-search-pipeline-review/` → `iago-pipeline-review/`

### File renames

1. `scripts/com.example.job-search-daily.plist` → `scripts/com.example.iago-daily.plist`

### Content updates (14 tracked files with `job-search` strings)

1. `README.md`
2. `docs/ROADMAP.md`
3. `docs/superpowers/specs/2026-06-26-iago-workflow-design.md`
4. `docs/superpowers/specs/2026-07-01-update-application-design.md`
5. `docs/superpowers/specs/2026-07-01-company-research-design.md`
6. `docs/superpowers/specs/2026-07-01-interview-prep-design.md`
7. `docs/superpowers/specs/2026-07-01-resume-feedback-design.md`
8. `.cursor/skills/iago-daily/SKILL.md` (after rename)
9. `.cursor/skills/iago-pipeline-review/SKILL.md` (after rename)
10. `.cursor/skills/update-application/SKILL.md`
11. `.cursor/skills/company-research/SKILL.md`
12. `.cursor/skills/interview-prep/SKILL.md`
13. `.cursor/skills/resume-feedback/SKILL.md`
14. `scripts/run-daily-search.sh`
15. `scripts/com.example.iago-daily.plist` (after rename)

### Cross-skill reference updates

All skills that reference `job-search-daily` or `job-search-pipeline-review` by name or path must point to `iago-daily` and `iago-pipeline-review`. Includes "Not this skill" lines and orchestration notes in `update-application`, `company-research`, `resume-feedback`, and pipeline/daily skills.

## Automation

### `scripts/run-daily-search.sh`

- Prompt path: `.cursor/skills/iago-daily/SKILL.md`
- Env var: `IAGO_TZ` (replace all `JOB_SEARCH_TZ` references)
- README example updated to match

### Launchd plist (`scripts/com.example.iago-daily.plist`)

- `Label`: `com.example.iago-daily`
- Comments reference `iago` clone path and new plist filename
- Install instructions in README and `iago-daily/SKILL.md` updated

## Post-merge checklist (manual, out of repo)

1. Rename GitHub repo to `iago` on github.com
2. `git remote set-url origin git@github.com:lachlanmag/iago.git`
3. Optionally rename local clone: `job-search-2` → `iago`
4. `launchctl unload ~/Library/LaunchAgents/com.example.job-search-daily.plist` (if loaded)
5. Remove old plist from `~/Library/LaunchAgents/`
6. Edit `scripts/com.example.iago-daily.plist`: set `__REPO_ROOT__` to new clone path
7. `cp scripts/com.example.iago-daily.plist ~/Library/LaunchAgents/`
8. `launchctl load ~/Library/LaunchAgents/com.example.iago-daily.plist`
9. Re-open repo in Cursor from new folder path

## Success criteria

- [ ] No remaining `job-search` strings in tracked files (except git history)
- [ ] Skill directories `iago-daily` and `iago-pipeline-review` exist; old names removed
- [ ] All six skills document slash and natural language triggers per Trigger model
- [ ] `/iago` and `/iago-daily` both documented for daily search
- [ ] Iago slash aliases retained for pipeline, update, brief, interview, feedback skills
- [ ] "Update applications" disambiguation applied (daily vs update-application)
- [ ] `scripts/run-daily-search.sh` points at `iago-daily/SKILL.md` and uses `IAGO_TZ`
- [ ] README clone instructions use `lachlanmag/iago`
- [ ] Post-merge checklist present in README or this spec

## Repository layout (after rebrand)

```
iago/
  .cursor/skills/
    iago-daily/                    # Daily search; /iago, /iago-daily
    iago-pipeline-review/          # Pipeline triage; /iago-pipeline
    update-application/            # Tracker updates; /iago-update
    company-research/              # Role brief; /iago-brief
    interview-prep/                # Talking points; /iago-interview
    resume-feedback/               # Resume review; /iago-feedback
  scripts/
    init-data.sh
    run-daily-search.sh
    com.example.iago-daily.plist
  docs/
    ROADMAP.md
    superpowers/specs/
    superpowers/plans/
```
