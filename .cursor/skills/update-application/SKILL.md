---
name: update-application
description: >-
  Update pipeline status and dates in applications.yaml. Automatically runs
  company-research when a role is shortlisted and interview-prep when an
  application is submitted. Use when the user shortlists, applies, rejects,
  withdraws, moves to interview, or updates tracker status.
---

# Update application

## When to use

- User shortlists, applies, rejects, withdraws, or changes interview stage
- User says "set [Company] to applied", "shortlist [Company]", or "update my tracker"
- Any workflow that changes `status` in `data/applications.yaml`

**Orchestrator:** This skill writes the tracker, then **immediately** invokes chained skills in the same session (no separate user prompt).

## Files

| File | Purpose |
|------|---------|
| `data/applications.yaml` | Pipeline tracker (read + write) |
| `data/config.yaml` | Optional defaults |

## Status values

| Status | Meaning |
|--------|---------|
| `discovered` | Found in search, not reviewed |
| `shortlisted` | Good fit, preparing to apply |
| `applied` | Application submitted |
| `interview` | In interview process |
| `rejected` | Declined |
| `withdrawn` | User withdrew |
| `offer` | Received offer |
| `closed` | Listing expired / filled |

## Workflow

### 1. Resolve the role

Identify row by `id`, or `company` (+ optional `title`). If ambiguous, ask once.

Confirm the status change the user wants and any dates (`applied`, `discovered` already set).

### 2. Validate transition

| To status | Typical from | Extra fields |
|-----------|--------------|--------------|
| `shortlisted` | `discovered` | `jd_path` set by chained `company-research`; optional `resume_status: none` |
| `applied` | `shortlisted` (or `discovered` if skip shortlist) | `applied: YYYY-MM-DD`, optional `channel` |
| `interview` | `applied` | Optional notes for stage/round |
| `rejected`, `withdrawn`, `offer`, `closed` | any open | Optional note with reason |

Warn if skipping `shortlisted` before `applied` but proceed if user confirms.

### 3. Write tracker

Update `data/applications.yaml`:

- Set `status` and date fields (`applied`, etc.)
- Set `channel` when provided (`direct`, `company_site`, `seek`, `linkedin`, `recruiter`, `referral`)
- Append timestamped note if user gave context

Do not remove existing `company_research` or `interview_prep` paths.

### 4. Chain follow-on skills (automatic)

Run in the **same turn** after the tracker write succeeds:

| New status | Chained skill | Action |
|------------|---------------|--------|
| `shortlisted` | `company-research` | Run full workflow for this row. Produce role brief artifact. |
| `applied` | `interview-prep` | Run full workflow for this row. Produce prep artifact. |
| `interview` | `interview-prep` | Run only if user asked for prep refresh or `interview_prep` is missing/stale |

Announce chaining briefly: "Shortlisted: running company research…" or "Applied: generating interview prep…"

If chained skill fails (e.g. listing closed, no JD), report the failure, leave status as written, and give manual next step.

### 5. Confirm to user

Summarize:

- Status change and dates
- Paths to any new artifacts (`company_research`, `interview_prep`)
- Suggested next action (e.g. tailor resume after brief, follow up after 14 days)

## Manual commands

> Shortlist [Company]

> Set [Company] to applied on 2026-07-01 via linkedin

> Update tracker: [Company] rejected

## Out of scope

- Discovering new roles (`job-search-daily`)
- Pipeline ranking (`job-search-pipeline-review`), but pipeline-review should chain `company-research` when it promotes rows to `shortlisted` with user confirmation
- Resume tailoring or feedback
