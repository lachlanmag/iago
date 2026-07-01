---
name: job-search-daily
description: >-
  Run the daily PM/PO/BA job search, surface new listings, and update the
  application tracker. Use when the user says daily job search, job hunt, find
  new jobs, update applications, or runs /job-search.
---

# Daily job search

## When to use

- User asks for a daily/weekly job search
- User wants new PM, Product Owner, or BA roles
- User asks to update or review their application tracker
- Cursor Automation or `/loop` triggers this skill

## Files (always read first)

| File | Purpose |
|------|---------|
| `data/config.yaml` | Search criteria and saved search URLs |
| `data/applications.yaml` | Tracker: applied / shortlisted / discovered |
| `data/seen-jobs.yaml` | Dedup list from prior runs |
| `data/recruiters.yaml` | Recruiter outreach (optional) |
| `profile.resume_path` in config | Local resume markdown for fit scoring |

Repo root is the Cursor workspace. All paths below are relative to repo root unless noted.

## Search rules (strict priority)

1. **Role order:** Use `config.yaml` → `role_priority` (typically PM → PO → BA, Senior variants included).
2. **Location:** Prefer `profile.location` first. Respect `profile.willing_to_relocate`.
3. **Outside local metro:** Apply `location_rules.outside_local` (typically remote-only).
4. **Industry:** Tag every role with an `industry` label from `config.yaml` → `industry_labels`.
5. **Industry awareness:** If a role's industry is in `industry_awareness.prefer_to_avoid`, **flag it** (⚠). If in `actively_targeting` or `preferences.industry_focus`, **highlight it** (★). Never exclude based on industry.
6. **Resume fit:** Score every role against `config.yaml` → `resume_fit` and the file at `profile.resume_path`. Set `resume_fit` to `strong`, `good`, `stretch`, or `weak` with a one-line `resume_fit_note`. Show flags: **✓ strong resume fit**, **✓ resume fit**, or **~ stretch fit**. Independent from industry ★/⚠.
7. **Work model:** Follow `preferences.work_model` for local roles.
8. **AI exposure:** Bonus only: do not filter roles out for lacking AI.
9. **Links:** Direct job listing URLs only (not search result pages).
10. **Listing freshness (at intake):** Before adding any role to the candidate pool, check the listing page for expiry/closed signals and closing dates. A visible job description alone is **not** proof the role is open.
11. **Dedup:** Before saving any role, run duplicate detection. Store the **canonical** (most direct) URL only.
12. **QA gate:** Before writing tracker files, run the mandatory **QA gate** (step 5). No role is saved or recommended in top picks until it passes.

## Daily workflow

### 1. Load state

- Read `data/config.yaml`, `data/applications.yaml`, `data/seen-jobs.yaml`, and the resume at `profile.resume_path`.
- Build dedup index from `applications.yaml` + `seen-jobs.yaml`: all URLs, `ats_id` values, and `company + title + location` keys.

### 2. Search for new roles

Search in the order defined in `config.yaml` → `search_sources.order`. Do **not** search `excluded_sources`.

For each board in config, use saved URLs and targeted web search (e.g. `site:seek.com.au/job "Product Manager" [city]`). Also check `watch_companies` on company ATS boards (Lever, Workable, Greenhouse, Ashby).

Prefer company ATS and gov direct links over aggregators. Use browser when SPA sites block fetch.

### 2a. Listing freshness at intake (required during search)

For **every** candidate role found during search: before scoring, tiering, or adding to the candidate pool: open the **canonical** listing URL and verify it is still accepting applications.

Read `config.yaml` → `listing_freshness`. Apply these rules:

| Check | Action |
|-------|--------|
| **Closed signals** | If page text matches any `closed_signals` phrase (case-insensitive), **skip immediately**. Log in daily report **Skipped expired / closed**. |
| **Closing date** | If `date_fields` show a date, parse it. Past date → skip. Within `closing_soon_days` → keep but flag **closing soon** in report. |
| **Open proof** | Require evidence from `open_proof`: active Apply control, no expired banner, URL resolves. Follow `board_hints`. |
| **Aggregator hits** | Resolve to employer ATS first, then run freshness check on the ATS URL: not the aggregator page alone. |
| **Archived JD trap** | If full JD is visible but an expired/closed banner exists, treat as **closed** regardless of body text. |

Record on each passing candidate (internal notes until save):

- `listing_verified: YYYY-MM-DD`
- `closes: YYYY-MM-DD` (if known)
- `closing_soon: true/false`

**Do not** add roles that fail intake freshness to the candidate pool or tracker.

### 2b. Duplicate detection (required before save)

For every candidate role, check against the dedup index using `config.yaml` → `deduplication.match_rules`:

| Rule | How |
|------|-----|
| `exact_url` | Normalize URL (strip tracking params, trailing slashes, lowercase host) |
| `ats_job_id` | Extract ID from `jobs.lever.co/{company}/{id}`, `jobs.workable.com/view/{id}`, `boards.greenhouse.io/{company}/jobs/{id}`, `jobs.ashbyhq.com/{company}/{id}` |
| `company_title_location` | Normalized company + title + location bucket per `deduplication.normalize` |

**If duplicate found:** do not create a new tracker row. If the new source has a **more direct** URL per `deduplication.canonical_url_priority`, update the existing entry's `url` and move the old URL to `alternate_urls`.

**Canonical URL priority** (highest wins):

1. Company ATS (Lever, Workable, Greenhouse, Ashby)
2. Gov direct
3. Council portal
4. Company careers page
5. Recruiter direct
6. Niche board
7. Aggregator (SEEK, LinkedIn, Indeed, Jora, Hatch wrapper)

**Aggregator resolution:** When a role is found on an aggregator, follow the apply link to find the employer ATS or careers URL. Save that as `url`. Record the aggregator link in `alternate_urls` only.

Log dedup actions in the daily run report section **Deduped this run**.

### 3. Score and tier results

Output tiers (adapt to user's location rules):

| Tier | Criteria |
|------|----------|
| **Tier 1** | Local metro + PM + B2B SaaS + hybrid |
| **Tier 2** | Local metro + PM (any strong product org) |
| **Tier 3** | Local metro + PO or Senior BA in SaaS/product company |
| **Tier 4** | Remote (country) + PM/PO (outside local metro) |
| **Tier 5** | Remote (country) + BA |

For each role include: company, title, industry, **resume fit flag**, location, work model, why it fits (1 line), direct URL, tier.

**Flag legend (independent: combine as needed):**

| Flag | Source | Meaning |
|------|--------|---------|
| ✓ strong resume fit | `resume_fit: strong` | Maps to 2+ resume themes |
| ✓ resume fit | `resume_fit: good` | Clear role + theme overlap |
| ~ stretch fit | `resume_fit: stretch` | Transferable but gaps in domain/craft |
| ★ industry focus | `industry_awareness.actively_targeting` or `preferences.industry_focus` | Industry you're pivoting into |
| ⚠ prefer to avoid | `industry_awareness.prefer_to_avoid` | Industry heads-up before applying |

Skip roles already in tracker with status `applied`, `interview`, `rejected`, `withdrawn`, `offer`, or `closed`.

### 4. Build candidate set

Combine intake-passing new roles. Reject any that failed freshness at step 2a (already logged).

### 5. QA gate (mandatory: run before any tracker write)

Read `config.yaml` → `qa_gate`. This step is **not optional**.

Run every check in `qa_gate.checks`:

| Check | What to do |
|-------|------------|
| **dedup_all_candidates** | Re-run step 2b on full candidate set. Merge URL upgrades; remove duplicate rows. |
| **verify_listing_open** | Re-fetch each candidate's canonical URL. Re-apply `listing_freshness` rules. Fail = exclude from save. |
| **verify_url_resolves** | Canonical URL must not 404. Use browser for SPAs that block curl. |
| **spot_check_tracker** | Re-verify all `discovered` and `shortlisted` rows in `applications.yaml`. Past closing date or closed banner → set `status: closed`. |
| **reconcile_top_picks** | Top 3 apply picks must each pass `verify_listing_open`. Swap in next eligible role if any fail. |

**On failure** (per `qa_gate.on_failure`):

- **New role:** do not append to tracker files; log reason in **QA gate** report section.
- **Existing tracker role:** update `status: closed` with note; list under **Closed since last run**.
- **Top pick:** replace with next passing role.

### 6. Write daily run report

Create or overwrite:

`data/daily-runs/YYYY-MM-DD.md`

**Layout principle:** Lead with pipeline and action. Put QA, skipped listings, dedup, and sources at the bottom as audit detail.

#### Above the fold (read this first)

1. **Summary**: 3–5 bullets: new roles saved, closed since last run, market read, **Prioritize today** (top 3 QA-verified picks)
2. **New roles this run**: tiered table (Tier, Company, Title, Industry, Flags, Location, Work model, Closes, Link)
3. **Application pipeline**: status counts from `applications.yaml`
4. **Shortlist**: all `shortlisted` rows with listing status and next action
5. **Open tracker**: `discovered` rows worth revisiting (QA-verified this run)
6. **Flags summary**: all non-`closed` tracker roles
7. **Closed since last run**: rows set to `closed` this run only

#### Audit / detail (below the fold)

8. **Skipped expired / closed**
9. **Closing soon**
10. **QA gate**
11. **Deduped this run**
12. **Sources checked**

Use `---` between major sections.

### 7. Update tracker files (only after QA gate passes)

- Write **only** roles that passed step 5 QA gate.
- Append genuinely **new** roles to `data/applications.yaml` with `status: discovered`, `industry`, `resume_fit`, `resume_fit_note`, canonical `url`, `discovered: YYYY-MM-DD`.
- Append to `data/seen-jobs.yaml` with `first_seen`, canonical `url`, optional `alternate_urls`, `ats_id`, and `listing_verified: YYYY-MM-DD`.
- When a duplicate has a better canonical URL, update the existing entry's `url` (do not duplicate rows).
- Set `status: closed` on existing rows only when QA spot-check or search verified the listing closed.

### 8. Offer next actions

End with:

- Top 3 roles to apply to this week
- If `discovered` count is high (roughly 5+), suggest running `job-search-pipeline-review` to triage and pick apply targets for the week
- Reminder: shortlisting via `update-application` or pipeline review saves the JD and runs `company-research` automatically
- Reminder: use `update-application` to set `applied` (chains `interview-prep` automatically) or shortlist via pipeline review (chains `company-research`)

## Status values

| Status | Meaning |
|--------|---------|
| `discovered` | Found in search, not yet reviewed |
| `shortlisted` | Good fit, preparing or ready to apply |
| `applied` | Application submitted |
| `interview` | In interview process |
| `rejected` | Declined |
| `withdrawn` | User withdrew |
| `offer` | Received offer |
| `closed` | Listing expired / role filled |

## Freshness failure examples (do not save)

| Board | Trap | Correct action |
|-------|------|----------------|
| EthicalJobs | Full JD visible; footer says expired | Skip at intake; log as expired |
| SEEK | Detail page says no longer accepting | Skip; do not save from search snippet |
| Lever | 404 or missing Apply | Skip; mark closed if already in tracker |
| Gov boards | Closing date in the past | Skip or set tracker `closed` |
| Aggregator | Only aggregator page checked; ATS not verified | Resolve ATS URL and verify open there |

## Manual commands

**Run once now (in chat):**

> Run the daily job search

**Run once locally (headless CLI):**

```bash
bash scripts/run-daily-search.sh
```

Requires `cursor agent login` once. Logs: `data/logs/latest.log`

**Schedule locally on macOS (weekdays 8 AM):**

```bash
chmod +x scripts/run-daily-search.sh scripts/init-data.sh
# Edit scripts/com.example.job-search-daily.plist: replace __REPO_ROOT__
cp scripts/com.example.job-search-daily.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.example.job-search-daily.plist
```

**While Cursor is open:**

> /loop 1d Run the daily job search skill and update the tracker

**Mark an application:**

> Set [Company] to applied on [date] via update-application

## Out of scope

This skill covers job sourcing and application tracking only. Resume tailoring, cover letters, and PDF export stay external (use whatever you prefer after shortlisting). After tailoring, use `resume-feedback` for review, then apply via `update-application`.
