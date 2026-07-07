---
name: iago-setup
description: >-
  Guided job search onboarding that initializes gitignored data/ files and
  writes config.yaml from conversation. Use when the user says set up job
  search, configure job search, job search onboarding, first time setup,
  initialize job search, help me configure iago, or runs /iago-setup.
---

# Iago setup

## When to use

- First-time setup after cloning the repo
- User wants to configure search criteria without hand-editing YAML
- User says "set up job search", "configure job search", "job search onboarding", "first time setup", "initialize job search", "help me configure iago"
- User runs `/iago-setup`
- User re-runs setup to update `data/config.yaml`

**Orchestrator:** Conversational wizard. One section at a time. Recap before each write. Use `AskQuestion` for multi-choice.

## Files

| File | Purpose |
|------|---------|
| `examples/config.example.yaml` | Schema reference and default values |
| `data/config.yaml` | Primary write target (gitignored) |
| `data/applications.yaml` | Tracker (init only in v1) |
| `data/seen-jobs.yaml` | Dedup index (init only) |
| `data/recruiters.yaml` | Recruiter tracker (init only) |
| `profile.resume_path` in config | Local resume for fit theme extraction |

Repo root is the Cursor workspace.

## Workflow

### 1. Detect state

Check whether core files exist: `data/config.yaml`, `data/applications.yaml`, `data/seen-jobs.yaml`.

If any are missing, run:

```bash
bash scripts/init-data.sh
```

If `data/config.yaml` exists with non-placeholder values, use `AskQuestion`:

| Mode | Behavior |
|------|----------|
| **Fresh setup** | Copy `examples/config.example.yaml` → `data/config.yaml` (tracker files unchanged) |
| **Update config** | Section-by-section edits only |
| **Cancel** | Stop without writes |

**Placeholder signals:** `Your City, State`, `/path/to/your/master-resume.md`, `Example SaaS Co`, empty `proof_points` with otherwise example-only config.

### 2. Profile

Collect and confirm:

- `profile.resume_path` (absolute path; **verify file exists** before continuing)
- `profile.location` (city, state/region, country as user prefers)
- `profile.willing_to_relocate` (boolean)

Suggest keeping the resume outside this repo.

### 3. Roles

Present default `role_priority` from example config. Ask user to confirm or reorder. Typical order: PM → Senior PM → PO → Senior PO → BA → Senior BA. Drop titles they do not want.

### 4. Location rules

Use `AskQuestion` where helpful:

| Field | Question |
|-------|----------|
| `location_rules.local.include_hybrid` | Accept hybrid roles in local metro? |
| `location_rules.local.include_on_site` | Accept on-site roles in local metro? |
| `location_rules.local.include_remote` | Accept remote roles in local metro? |
| `location_rules.outside_local.require_remote` | Outside local metro: remote only? (default yes) |

### 5. Preferences

Collect:

- `preferences.industry` (free text, e.g. "B2B SaaS preferred")
- `preferences.industry_focus` (optional single label from `industry_labels`, or null)
- `preferences.work_model` (e.g. hybrid preferred for local metro)
- `preferences.min_seniority` (e.g. mid, senior)
- `preferences.ai_exposure` (default `bonus_only`)

### 6. Industry awareness

Collect two optional lists (flag-only; never filter search):

- `industry_awareness.actively_targeting` (★ highlight in daily reports)
- `industry_awareness.prefer_to_avoid` (⚠ flag only)

Use labels from `industry_labels` in config when possible.

### 7. Resume fit

1. Read the file at `profile.resume_path`.
2. Suggest 4–6 `resume_fit.core_themes` tailored to PM/PO/BA search.
3. Suggest optional `resume_fit.proof_points` (concrete highlights from resume).
4. Present suggestions; user confirms or edits.
5. Leave `flag_strong`, `flag_good`, `flag_stretch`, `levels`, `strong_signals`, `stretch_signals` at example defaults.

### 8. Search sources

**Prerequisite:** `profile.location` and `role_priority` already set.

**Step A — Present default boards by name** (not URLs):

| Display name | Config `id` |
|--------------|-------------|
| SEEK | `seek` |
| LinkedIn | `linkedin` |
| Company boards (ATS watch list) | `company_boards` |
| We Love Product | `niche_boards` |
| Indeed | `aggregators` |
| Employment Hero Jobs | `recruiters` |

**Step B — Ask:** which defaults to enable? Any additional sites by name or URL?

**Step C — URL resolution:**

- For each **enabled** default: build or discover metro-specific saved-search URLs from `location` + top `role_priority` titles. Use web search when needed. Write to `search_sources.boards[].urls`.
- For **disabled** defaults: add board `id` to `excluded_sources`.
- For **user-added** sites: if URL given, verify it resolves; if name only, search for the board's job listing page for their market. Add new entry to `search_sources.boards` with unique `id`, `name`, `urls`.

**Step D — Confirm** final enabled board list (names only) before write.

Leave `search_sources.order`, `deduplication`, `listing_freshness`, and `qa_gate` at example defaults.

### 9. Watch list

Collect `watch_companies`: company names to monitor on ATS boards (Lever, Workable, Greenhouse, Ashby). Optional; empty list is fine.

### 10. Validate before write

| Check | On failure |
|-------|------------|
| `profile.resume_path` exists | Block save; ask for corrected path |
| At least one search source enabled | Block save |
| URLs resolve (fetch or browser) | Warn; allow save if user confirms |

Remind user: all output stays in gitignored `data/`. After setup, run `git status` to confirm nothing under `data/` is staged.

### 11. Write YAML

- Merge collected values into `data/config.yaml`.
- On **update** mode: preserve keys outside edited sections.
- Do not modify tracker files unless user is in fresh setup and config was reset.

### 12. Confirm to user

Summarize:

- Sections written
- Path to `data/config.yaml`
- Enabled search boards (names)
- **Next step:** Run the daily job search (`iago-daily` or "Run the daily job search")
- After repo upgrades: `bash scripts/reconcile-config.sh`

## Default board reference

When resolving URLs, start from `examples/config.example.yaml` → `search_sources.boards` structure. Adapt URLs to user's `profile.location` and market (AU, US, UK, etc.).

## Out of scope

- Launchd plist substitution
- Regional presets or source catalog
- Config validation script
- Importing applications from spreadsheet
- Customizing `deduplication`, `listing_freshness`, `qa_gate`
- Committing any `data/` content

## Context

- Repo: /Users/lachlanmagee/git-repos/job-search
- Branch: issue-1-iago-setup (already checked out)
- This is task 1 of 6 implementing iago-setup per GitHub issue #1
- Match style of existing skills like `.cursor/skills/update-application/SKILL.md`
- Follow existing skill frontmatter YAML format with name and description fields
