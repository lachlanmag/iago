# Update Application Skill: Design

## Goal

Add a Cursor-native **`update-application`** skill that updates pipeline status and dates in `data/applications.yaml`, then chains follow-on skills in the same session without a separate user prompt.

The skill is the orchestrator for the v1.1 apply workflow: shortlist chains `company-research`; apply chains `interview-prep`.

No personal tracker data or artifacts are committed to git.

## Scope

### In scope (v1.1)

- **`update-application` skill**: resolve role, validate transition, write tracker, chain skills, confirm to user
- **Status transitions**: `discovered`, `shortlisted`, `applied`, `interview`, `rejected`, `withdrawn`, `offer`, `closed`
- **Automatic chaining**:
  - `shortlisted` → `company-research` (JD cache + role brief)
  - `applied` → `interview-prep`
  - `interview` → `interview-prep` only on user refresh request or missing/stale prep
- **README and ROADMAP updates**: document triggers and chaining

### Out of scope (v1.1)

- Discovering new roles (`job-search-daily`)
- Pipeline ranking (`job-search-pipeline-review`, though pipeline review may call this pattern when promoting rows)
- Resume tailoring or `resume-feedback`
- Setting `resume_status: ready` after feedback (ROADMAP Later #16)
- Headless CLI script

### Relationship to existing workflow

```
job-search-daily           → discover + score
job-search-pipeline-review → triage; may promote to shortlisted + chain company-research
update-application         → shortlist (chains company-research)
[external tailoring]       → tailored resume JSON
resume-feedback            → review before apply
update-application         → apply (chains interview-prep)
```

## Architecture

**Approach:** Single skill file only (no `prompt.md`). Workflow in `SKILL.md`; generation delegated to chained skills.

```
job-search/
  .cursor/skills/update-application/
    SKILL.md
  docs/superpowers/specs/
    2026-07-01-update-application-design.md
```

### Tracked vs local data

| Path | Git | Purpose |
|------|-----|---------|
| `.cursor/skills/update-application/` | tracked | Orchestrator skill |
| `data/applications.yaml` | **ignored** | Pipeline tracker (read + write) |

## Workflow behavior

### 1. Resolve the role

Identify row by `id`, or `company` (+ optional `title`). If ambiguous, ask once. Confirm status change and dates.

### 2. Validate transition

| To status | Typical from | Extra fields |
|-----------|--------------|--------------|
| `shortlisted` | `discovered` | `jd_path` set by chained `company-research`; optional `resume_status: none` |
| `applied` | `shortlisted` (or `discovered` if skip shortlist) | `applied: YYYY-MM-DD`, optional `channel` |
| `interview` | `applied` | Optional notes for stage/round |
| `rejected`, `withdrawn`, `offer`, `closed` | any open | Optional note with reason |

Warn if skipping `shortlisted` before `applied` but proceed if user confirms.

### 3. Write tracker

Update `data/applications.yaml`: `status`, date fields, optional `channel`, timestamped notes. Do not remove existing `company_research`, `jd_path`, or `interview_prep` paths.

### 4. Chain follow-on skills

Run in the **same turn** after tracker write succeeds:

| New status | Chained skill | Action |
|------------|---------------|--------|
| `shortlisted` | `company-research` | Full workflow: JD + role brief |
| `applied` | `interview-prep` | Full prep artifact |
| `interview` | `interview-prep` | Only if user asked for refresh or prep missing/stale |

Announce chaining briefly. If chained skill fails, report failure, leave status as written, give manual next step.

### 5. Confirm to user

Summarize status change, artifact paths, and suggested next action.

## Data model

### Tracker fields touched

| Field | When set |
|-------|----------|
| `status` | Every update |
| `applied` | Status `applied` |
| `channel` | Optional on apply (`direct`, `company_site`, `seek`, `linkedin`, `recruiter`, `referral`) |
| `jd_path` | By chained `company-research` on shortlist |
| `company_research` | By chained `company-research` |
| `interview_prep` | By chained `interview-prep` |
| `notes` | Optional append on any transition |

## Trigger phrases

| Trigger | Action |
|---------|--------|
| `Shortlist [Company]` | Set `shortlisted`, chain `company-research` |
| `Set [Company] to applied on [date]` | Set `applied`, chain `interview-prep` |
| `Update tracker: [Company] rejected` | Set terminal status |

## Documentation updates (implementation)

| File | Change | Status |
|------|--------|--------|
| `README.md` | Apply workflow, chaining table | Done |
| `docs/ROADMAP.md` | Mark shipped | Done |
| `.cursor/skills/job-search-daily/SKILL.md` | Point manual commands here | Done |
| `.cursor/skills/job-search-pipeline-review/SKILL.md` | Chain on shortlist promotion | Done |

## Testing and validation

- **Shortlist:** Status `shortlisted`; `company-research` runs; `jd_path` and `company_research` set.
- **Apply:** Status `applied` with date; `interview-prep` runs; `interview_prep` set.
- **Failure:** Closed listing during chain leaves status but reports manual step.
- **Sanitization:** `git status` clean after runs.

## Success criteria

1. User can shortlist or apply via natural language without hand-editing YAML.
2. Chained skills run in the same session without a second prompt.
3. README documents the orchestrator and chaining table.
4. Skill behavior matches this spec and `.cursor/skills/update-application/SKILL.md`.

## Future work (not v1.1)

| Item | Notes |
|------|-------|
| `resume_status: ready` | After user confirms apply-ready post `resume-feedback` (ROADMAP #16) |
| Validation script | Optional YAML schema for status transitions |
