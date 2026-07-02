---
name: job-search-pipeline-review
description: >-
  Review the open application pipeline, re-verify listings, rank roles by fit
  and urgency, and recommend which jobs to shortlist or apply to first. Use when
  the user asks to review the pipeline, prioritize applications, decide what to
  shortlist, triage discovered roles, or runs /pipeline-review.
---

# Pipeline review

## When to use

- User wants to triage `discovered` roles and decide what to shortlist
- User asks which open jobs to apply to first this week
- User wants a ranked view of the pipeline without running a new search
- Weekly review after one or more daily search runs
- User says "review my pipeline", "prioritize applications", or `/pipeline-review`

**Not this skill:** finding new listings (use `job-search-daily`), marking applied/rejected (use `update-application`).

## Files (always read first)

| File | Purpose |
|------|---------|
| `data/config.yaml` | Role priority, location rules, industry/resume fit rubric, listing freshness |
| `data/applications.yaml` | Pipeline tracker |
| `data/seen-jobs.yaml` | Canonical URLs, `listing_verified`, closing hints |
| `profile.resume_path` in config | Resume for fit re-scoring |
| Latest `data/daily-runs/*.md` | Optional context from most recent daily run |

Repo root is the Cursor workspace. Paths below are relative to repo root.

## Scope

Review roles with status:

| Status | Include in review |
|--------|-------------------|
| `discovered` | Yes: primary triage target |
| `shortlisted` | Yes: prioritize apply order |
| `applied` | Summary only: note stale applications (>14 days, no response) |
| `interview` | Summary only: flag prep needs |
| `rejected`, `withdrawn`, `offer`, `closed` | Exclude |

## Review workflow

### 1. Load state

- Read `data/config.yaml`, `data/applications.yaml`, `data/seen-jobs.yaml`, and resume at `profile.resume_path`.
- Count pipeline by status.
- Note roles with missing `resume_fit`, `industry`, or `url`.

### 2. Re-verify open listings (required)

For every `discovered` and `shortlisted` row, open the **canonical** `url` and apply `config.yaml` → `listing_freshness` (same rules as `job-search-daily` step 2a).

| Outcome | Action |
|---------|--------|
| Closed / expired | Mark for `status: closed` with reason |
| Closing within `closing_soon_days` | Flag **closing soon**: boost priority |
| Still open | Record `listing_verified: YYYY-MM-DD` |

Use browser for SPAs that block fetch. Resolve aggregator URLs to employer ATS when needed.

**Do not** recommend apply or shortlist for roles that fail this check.

### 3. Score each open role

Use the same signals as daily search (do not invent new tiers):

**Tier** (from `job-search-daily`: local metro + role + industry + work model):

| Tier | Criteria |
|------|----------|
| **Tier 1** | Local metro + PM + B2B SaaS + hybrid |
| **Tier 2** | Local metro + PM (any strong product org) |
| **Tier 3** | Local metro + PO or Senior BA in SaaS/product company |
| **Tier 4** | Remote (country) + PM/PO (outside local metro) |
| **Tier 5** | Remote (country) + BA |

**Flags** (independent: combine as needed):

| Flag | Source |
|------|--------|
| ✓ strong resume fit | `resume_fit: strong` or re-score against resume |
| ✓ resume fit | `resume_fit: good` |
| ~ stretch fit | `resume_fit: stretch` |
| ★ industry focus | `industry_awareness.actively_targeting` or `preferences.industry_focus` |
| ⚠ prefer to avoid | `industry_awareness.prefer_to_avoid` |

Re-score `resume_fit` when stale, missing, or resume changed since `discovered` date. Update internal notes; persist to tracker only in step 7 if user approves.

**Urgency modifiers** (applied after tier):

| Signal | Effect |
|--------|--------|
| Closing within 7 days | +2 priority |
| Closing within 14 days | +1 priority |
| Discovered >21 days ago, still open | −1 priority (stale interest unless strong fit) |
| Already `shortlisted` with `resume_status: ready` | +1 priority (apply-ready) |
| ⚠ industry flag | Surface in rationale; do not auto-demote |

### 4. Rank and recommend

Produce three lists:

1. **Apply this week**: top 3–5 open roles (mix of `shortlisted` ready-to-apply and high-tier `discovered` worth promoting). Each needs: company, title, tier, flags, closes date, one-line why now, direct URL, suggested action (`apply`, `shortlist then apply`, `research company first`).
2. **Shortlist candidates**: `discovered` roles worth promoting to `shortlisted` (not yet in apply-this-week if user bandwidth is limited).
3. **Deprioritize / pass**: open roles that are stretch/weak fit, wrong role type vs `role_priority`, or low tier with no urgency. Suggest `closed` only if listing expired; otherwise leave as `discovered` with "pass for now" note.

**Tie-breakers** (in order): tier → resume fit (strong > good > stretch) → closing soon → ★ industry → lower tier number wins → `shortlisted` over `discovered`.

Respect `role_priority` order when comparing similar-tier roles.

### 5. Bandwidth check

Ask or infer weekly apply capacity (default: 3 applications/week if user does not specify).

- If `shortlisted` count exceeds capacity × 2, flag **pipeline bloat** and name roles to apply, defer, or pass.
- Prefer depth on top picks over spreading across many stretch roles.

### 6. Write pipeline review report

Create or overwrite:

`data/pipeline-reviews/YYYY-MM-DD.md`

**Layout:** Lead with decisions. Audit detail at the bottom.

#### Above the fold

1. **Summary**: pipeline counts, listings closed this review, **Apply this week** (numbered list), bandwidth note
2. **Ranked open pipeline**: table: Rank, Status, Company, Title, Tier, Flags, Closes, Listing, Recommended action
3. **Shortlist promotions**: `discovered` → `shortlisted` recommendations with rationale
4. **Apply queue**: current `shortlisted` rows in suggested submit order
5. **Needs attention**: stale `applied`, upcoming interviews, missing fields
6. **Pass for now**: roles to leave as `discovered` without action

#### Below the fold

7. **Closed this review**: roles verified closed (pending tracker update)
8. **Listing verification log**: URL, result, date checked
9. **Score changes**: any `resume_fit` re-scores vs tracker

Use `---` between major sections.

### 7. Update tracker (conditional)

**Auto-write without asking:**

- Set `status: closed` on roles verified closed in step 2
- Update `listing_verified` in `seen-jobs.yaml` when canonical URL unchanged

**Ask user before writing:**

- `discovered` → `shortlisted`
- `resume_fit` / `resume_fit_note` updates
- New `notes` on pass/deprioritize decisions
- `resume_status` changes

If user confirms promotions in chat, apply updates to `data/applications.yaml` immediately. For each row promoted to `shortlisted`, **automatically run `company-research`** in the same session (role brief artifact + tracker `company_research` path).

### 8. Offer next actions

End with:

- Numbered apply order for the week
- Which roles to promote to `shortlisted` (if not already done)
- Reminder: promoting to `shortlisted` chains `company-research` (saves JD to `data/jds/` + role brief)
- Optional: "Run daily job search" if pipeline is thin after closing stale roles

## Output principles

- **Compare roles relative to each other**, not just absolute fit scores.
- **Urgency beats perfect fit** when closing dates are near and fit is at least `good`.
- **Never recommend apply** on unverified or closed listings.
- **Be decisive**: rank everything in scope; avoid ties without explanation.
- Flag ⚠ industries explicitly in rationale; let the user decide.

## Manual commands

**Run in chat:**

> Review my pipeline and tell me what to prioritize

> Which discovered roles should I shortlist?

**After daily search (typical weekly rhythm):**

> Run pipeline review. I want to triage discovered roles and pick apply targets for this week

**Schedule (optional, with `/loop`):**

> /loop 7d Run the pipeline review skill and write the report

## Out of scope

- Searching job boards for new listings
- Resume tailoring, cover letters, PDF export
- Interview prep after apply (automatic via `update-application` → `interview-prep`)
