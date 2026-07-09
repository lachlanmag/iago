# Daily job search

## When to use

- User asks for a daily/weekly job search
- User wants new roles matching their configured `role_priority`
- User says "run the job search for today", "check for jobs today", or "what's new on the boards"
- User asks to update the tracker from today's search (add new `discovered` rows; not status changes)
- User runs `/iago` or `/iago-daily`

## Files (always read first)

| File | Purpose |
|------|---------|
| `$REPO_ROOT/data/config.yaml` | Search criteria and saved search URLs |
| `$REPO_ROOT/data/applications.yaml` | Tracker: applied / shortlisted / discovered |
| `$REPO_ROOT/data/seen-jobs.yaml` | Dedup list from prior runs |
| `$REPO_ROOT/data/recruiters.yaml` | Recruiter outreach (optional) |
| `profile.resume_path` in config | Local resume markdown for fit scoring |

**Prerequisite:** If `$REPO_ROOT/data/config.yaml` is missing or still has example placeholders, stop and tell the user to run `iago-setup` (or `bash "$REPO_ROOT/scripts/init-data.sh"` then configure manually).

## Search rules (strict priority)

1. **Role order:** Use `$REPO_ROOT/data/config.yaml` → `role_priority` in the order listed.
2. **Location:** Prefer `profile.location` first. Respect `profile.willing_to_relocate`.
3. **Outside local metro:** Apply `location_rules.outside_local` (typically remote-only).
4. **Industry:** Tag every role with an `industry` label from `$REPO_ROOT/data/config.yaml` → `industry_labels`.
5. **Industry awareness:** If a role's industry is in `industry_awareness.prefer_to_avoid`, **flag it** (⚠). If in `actively_targeting` or `preferences.industry_focus`, **highlight it** (★). Never exclude based on industry.
6. **Resume fit:** Score every role against `config.yaml` → `resume_fit` and the file at `profile.resume_path`. Set `resume_fit` to `strong`, `good`, `stretch`, or `weak` with a one-line `resume_fit_note`. Show flags: **✓ strong resume fit**, **✓ resume fit**, or **~ stretch fit**. Independent from industry ★/⚠.
7. **Work model:** Follow `preferences.work_model` for local roles.
8. **AI exposure:** Bonus only: do not filter roles out for lacking AI.
9. **Links:** Prefer the strongest direct listing URL available, but do **not** reject a role only because no non-aggregator direct link exists. Save the best available live listing page, not search result pages.
10. **Listing freshness (at intake):** Before adding any role to the candidate pool, check the best available listing page for expiry/closed signals and closing dates. A visible job description alone is **not** proof the role is open.
11. **Dedup:** Before saving any role, run duplicate detection. Store the strongest verified canonical URL available for that role, even if it is an aggregator page.
12. **QA gate:** Before writing tracker files, run the mandatory **QA gate** (step 5). No role is saved or recommended in top picks until it passes.

## Daily workflow

### 1. Load state

- Read `$REPO_ROOT/data/config.yaml`, `$REPO_ROOT/data/applications.yaml`, `$REPO_ROOT/data/seen-jobs.yaml`, and the resume at `profile.resume_path`.
- Build dedup index from `$REPO_ROOT/data/applications.yaml` + `seen-jobs.yaml`: all URLs, `ats_id` values, and `company + title + location` keys.

### 2. Search for new roles

Search in the order defined in `$REPO_ROOT/data/config.yaml` → `search_sources.order`. Do **not** search `excluded_sources`.

For each board in config, use saved URLs and targeted web search (e.g. `site:seek.com.au/job "Product Manager" [city]`). Also check `watch_companies` on company ATS boards (Lever, Workable, Greenhouse, Ashby).

Prefer company ATS and gov direct links over aggregators. Use browser when SPA sites block fetch.

### 2a. Listing freshness at intake (required during search)

For **every** candidate role found during search: before scoring, tiering, or adding to the candidate pool: identify the **best available listing page**, verify it is still accepting applications, and keep trying to upgrade to a stronger direct listing when possible.

Read `$REPO_ROOT/data/config.yaml` → `listing_freshness`. Apply these rules:

| Check | Action |
|-------|--------|
| **Closed signals** | If page text matches any `closed_signals` phrase (case-insensitive), **skip immediately**. Log in daily report **Skipped expired / closed**. |
| **Closing date** | If `date_fields` show a date, parse it. Past date → skip. Within `closing_soon_days` → keep but flag **closing soon** in report. |
| **Open proof** | Require evidence from `open_proof`: active Apply control, no expired banner, URL resolves. Follow `board_hints`. |
| **Direct-link upgrade** | If a stronger direct ATS/company/recruiter/gov listing can be found, use it as canonical. |
| **Aggregator fallback** | If no stronger direct page can be found, keep the best available live listing page as canonical if it clearly looks like a real open job listing. |
| **Archived JD trap** | If full JD is visible but an expired/closed banner exists, treat as **closed** regardless of body text. |

Record on each passing candidate (internal notes until save):

- `listing_verified: YYYY-MM-DD`
- `closes: YYYY-MM-DD` (if known)
- `closing_soon: true/false`
- `listing_proof: strong|medium|weak`
- `hidden_employer: true|false`
- `canonical_source_type: company_ats|company_careers|recruiter_direct|aggregator|gov_direct|niche_board|council_portal`
- optional `inferred_employer:` note when the employer is hidden but the JD strongly suggests one or more likely companies

**Proof strength (`listing_proof`):**

| Value | When to use |
|-------|-------------|
| `strong` | Direct ATS or official company page; active Apply control; no closed signal; enough JD detail to confirm it is a real listing |
| `medium` | Credible live listing from aggregator or recruiter page; active Apply/Quick Apply; no closed signal; substantial JD content |
| `weak` | Listing probably live but confidence is lower: hidden employer, thin metadata, weaker application-flow visibility, or partial open proof without contradiction |

`weak` listings may still be saved when they pass intake and QA with no closed signals.

**Do not** add roles that fail intake freshness to the candidate pool or tracker.

### 2b. Duplicate detection (required before save)

For every candidate role, check against the dedup index using `config.yaml` → `deduplication.match_rules`:

| Rule | How |
|------|-----|
| `exact_url` | Normalize URL (strip tracking params, trailing slashes, lowercase host) |
| `ats_job_id` | Extract ID from `jobs.lever.co/{company}/{id}`, `jobs.workable.com/view/{id}`, `boards.greenhouse.io/{company}/jobs/{id}`, `jobs.ashbyhq.com/{company}/{id}` |
| `company_title_location` | Normalized company + title + location bucket per `deduplication.normalize` |

**If duplicate found:** do not create a new tracker row. Compare both URLs against `deduplication.canonical_url_priority`. If the new source ranks **higher** and both pages are verified live, update the existing entry's `url` and move the old URL to `alternate_urls`. If the existing URL ranks higher, or only the existing URL is verified live, keep the existing canonical URL (even when it is an aggregator page).

**Canonical URL priority** (highest wins):

1. Company ATS (Lever, Workable, Greenhouse, Ashby)
2. Gov direct
3. Council portal
4. Company careers page
5. Recruiter direct
6. Niche board
7. Aggregator (SEEK, LinkedIn, Indeed, Jora, Hatch wrapper)

**Aggregator resolution:** When a role is found on an aggregator, follow the apply link to find the employer ATS or careers URL when possible. If a stronger direct listing is found and verified open, save that as `url` and record the aggregator link in `alternate_urls`. If no stronger direct listing can be found, save the live aggregator listing itself as canonical and mark its proof strength explicitly.

Log dedup actions in the daily run report section **Deduped this run**.

### 3. Score and tier results

Output tiers (adapt to user's `role_priority`, `location_rules`, and `preferences`):

| Tier | Criteria |
|------|----------|
| **Tier 1** | Local metro + highest `role_priority` + strongest preference match (industry, work model) |
| **Tier 2** | Local metro + highest `role_priority` |
| **Tier 3** | Local metro + secondary `role_priority` |
| **Tier 4** | Remote (country) + highest `role_priority` (outside local metro) |
| **Tier 5** | Remote (country) + secondary `role_priority` |

For each role include: company, title, industry, **flags**, location, work model, why it fits (1 line), canonical URL, tier.

**Flag legend (combine as needed in the report `Flags` column):**

| Flag | Source | Meaning |
|------|--------|---------|
| ✓ strong resume fit | `resume_fit: strong` | Maps to 2+ resume themes |
| ✓ resume fit | `resume_fit: good` | Clear role + theme overlap |
| ~ stretch fit | `resume_fit: stretch` | Transferable but gaps in domain/craft |
| ★ industry focus | `industry_awareness.actively_targeting` or `preferences.industry_focus` | Industry you're pivoting into |
| ⚠ prefer to avoid | `industry_awareness.prefer_to_avoid` | Industry heads-up before applying |
| hidden employer | `hidden_employer: true` | Listing does not directly confirm the employer identity |
| medium proof | `listing_proof: medium` | Open status looks credible, but evidence is weaker than a strong direct listing |
| weak proof | `listing_proof: weak` | Best available live listing passed QA, but should be treated as lower-confidence |

Skip roles already in tracker with status `applied`, `interview`, `rejected`, `withdrawn`, `offer`, or `closed`.

### 4. Build candidate set

Combine intake-passing new roles. Reject any that failed freshness at step 2a (already logged).

### 5. QA gate (mandatory: run before any tracker write)

Read `$REPO_ROOT/data/config.yaml` → `qa_gate`. This step is **not optional**.

Run every check in `qa_gate.checks`:

| Check | What to do |
|-------|------------|
| **dedup_all_candidates** | Re-run step 2b on full candidate set. Keep the higher-priority canonical URL when both duplicates are verified live; otherwise keep the stronger verified live URL. Merge upgrades; remove duplicate rows. |
| **verify_listing_open** | Re-fetch each candidate's chosen canonical listing page. Re-apply `listing_freshness` rules. Fail = exclude from save. Aggregator pages may pass when they are the best available live listing. |
| **verify_url_resolves** | Canonical URL must resolve to a usable listing page, not necessarily a direct employer site. Use browser for SPAs that block curl. |
| **spot_check_tracker** | Re-verify all `discovered` and `shortlisted` rows in `$REPO_ROOT/data/applications.yaml`. Past closing date or closed banner → set `status: closed`. |
| **reconcile_top_picks** | Top 3 apply picks must each pass `verify_listing_open`. Swap in next eligible role if any fail. |

**On failure** (per `qa_gate.on_failure`):

- **New role:** do not append to tracker files; log reason in **QA gate** report section.
- **Existing tracker role:** update `status: closed` with note; list under **Closed since last run**.
- **Top pick:** replace with next passing role.

In the **QA gate** report section, note when relevant:

- a stronger direct link was found and promoted to canonical
- no direct link was found, so the aggregator page was retained as canonical
- a hidden-employer role was saved with weaker proof (`medium` or `weak`)

### 6. Write daily run report

Create or overwrite:

`$REPO_ROOT/data/daily-runs/YYYY-MM-DD.md`

**Layout principle:** Lead with pipeline and action. Put QA, skipped listings, dedup, and sources at the bottom as audit detail.

#### Above the fold (read this first)

1. **Summary**: 3–5 bullets: new roles saved, closed since last run, market read, **Prioritize today** (top 3 QA-verified picks)
2. **New roles this run**: tiered table (Tier, Company, Title, Industry, Flags, Location, Work model, Closes, Link). Flags should include industry focus, hidden-employer status, and proof strength when relevant.
3. **Application pipeline**: status counts from `$REPO_ROOT/data/applications.yaml`
4. **Shortlist**: all `shortlisted` rows with listing status and next action
5. **Open tracker**: `discovered` rows worth revisiting (QA-verified this run)
6. **Flags summary**: all non-`closed` tracker roles
7. **Closed since last run**: rows set to `closed` this run only

#### Audit / detail (below the fold)

8. **Skipped expired / closed**
9. **Closing soon**
10. **Lower-confidence open roles**
11. **QA gate**
12. **Deduped this run**
13. **Sources checked**

**Lower-confidence open roles** (section 10): list roles saved this run with `listing_proof: medium` or `weak`, and/or `hidden_employer: true`. Use a short table or bullet list with Company, Title, proof strength, and Link. If an inferred employer hint exists, include it explicitly, for example:

- `Likely employer (inferred): Best Practice Software`
- `Possible employers (inferred): Best Practice Software, Genie Solutions`

Never present inferred identity as confirmed fact.

Use `---` between major sections.

### 7. Update tracker files (only after QA gate passes)

- Write **only** roles that passed step 5 QA gate.
- Append genuinely **new** roles to `$REPO_ROOT/data/applications.yaml` with `status: discovered`, `industry`, `resume_fit`, `resume_fit_note`, canonical `url`, `discovered: YYYY-MM-DD`, and when known `listing_verified`, `listing_proof`, `hidden_employer`, `canonical_source_type`.
- Append to `$REPO_ROOT/data/seen-jobs.yaml` with `first_seen`, canonical `url`, optional `alternate_urls`, `ats_id`, `listing_verified: YYYY-MM-DD`, and when known `listing_proof`, `hidden_employer`, `canonical_source_type`.
- When the employer is hidden, keep the canonical `company` field generic (for example `Private Advertiser` or recruiter name) unless the listing directly evidences the employer. If the JD strongly suggests one or more likely employers, include that only as an explicitly labeled inferred note or report flag, never as confirmed company identity. Use evidence such as location, industry, product domain, salary band, customer type, and watch-company matches. If multiple employers are plausible, preserve the ambiguity rather than forcing one name.
- When a duplicate has a better canonical URL, update the existing entry's `url` (do not duplicate rows).
- Set `status: closed` on existing rows only when QA spot-check or search verified the listing closed.

### 8. Offer next actions

End with:

- Top 3 roles to apply to this week
- If `discovered` count is high (roughly 5+), suggest running `iago-pipeline-review` to triage and pick apply targets for the week
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
| Aggregator | Page is only a search/snippet result, or the listing lacks enough open proof | Skip; do not save unless the best available live listing page clearly looks open |

## Manual commands

**Run once now (in chat):**

> Run the daily job search

**Run once locally (headless CLI):**

```bash
bash "$REPO_ROOT/scripts/run-daily-search.sh"
```

Requires `cursor agent login` once. Logs: `$REPO_ROOT/data/logs/latest.log`

**In Cursor chat (interactive):**

> /loop 1d Run the daily job search skill and update the tracker

**Mark an application:**

> Set [Company] to applied on [date] via update-application

## Out of scope

This skill covers job sourcing and application tracking only. Resume tailoring, cover letters, and PDF export stay external when you use them. Run `resume-feedback` to review your resume against the JD before apply (markdown from `profile.resume_path` by default), then apply via `update-application`.
