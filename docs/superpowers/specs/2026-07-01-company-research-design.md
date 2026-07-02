# Company Research Skill: Design

## Goal

Add a Cursor-native **`company-research`** skill that produces a **role brief** for a shortlisted job from the listing, company site, tracker context, and master resume themes.

On shortlist, the skill also caches the **full job description** to `data/jds/` and sets `jd_path` on the tracker row for downstream `resume-feedback` and `interview-prep`.

Runs automatically when a role is promoted to `shortlisted` (via `update-application` or pipeline review). No personal data committed to git.

## Scope

### In scope (v1.1)

- **`company-research` skill**: load context, web research, verbatim prompt, save JD + brief, update tracker
- **`prompt.md`**: mandatory brief prompt with fixed markdown headings
- **Gitignored `data/jds/`**: full JD markdown (`YYYY-MM-DD-{company-slug}-{title-slug}.md`)
- **Gitignored `data/company-research/`**: role brief artifacts (same slug pattern)
- **Tracker fields**: `jd_path`, `company_research`
- **Optional config**: `profile.output_language` (default English)
- **Idempotency**: skip if `company_research` on row points to today's artifact for this row

### Out of scope (v1.1)

- Updating status to `shortlisted` (caller: `update-application` or pipeline review)
- Resume tailoring or `resume-feedback`
- Interview prep (`interview-prep` after apply)
- Inventing company facts, funding, or headcount

### Relationship to existing workflow

```
update-application / pipeline-review → shortlisted
company-research                     → data/jds/ + data/company-research/ + tracker paths
resume-feedback                      → uses jd_path
update-application                   → applied
interview-prep                       → uses jd_path + optional brief
```

## Architecture

**Approach:** Single skill + separate prompt file (same pattern as `resume-feedback`).

```
iago/
  .cursor/skills/company-research/
    SKILL.md
    prompt.md
  data/                         # gitignored
    jds/
      YYYY-MM-DD-{company-slug}-{title-slug}.md
    company-research/
      YYYY-MM-DD-{company-slug}-{title-slug}.md
  docs/superpowers/specs/
    2026-07-01-company-research-design.md
```

### Tracked vs local data

| Path | Git | Purpose |
|------|-----|---------|
| `.cursor/skills/company-research/` | tracked | Skill + brief prompt |
| `data/jds/` | **ignored** | Full JD cache |
| `data/company-research/` | **ignored** | Role briefs |
| `profile.resume_path` | **local only** | Fit themes input |

**Setup:** `scripts/init-data.sh` creates `data/jds/` and `data/company-research/`.

## Inputs

| Placeholder / source | Required |
|----------------------|----------|
| Tracker row (`id` or company + title) | Yes |
| Canonical listing `url` | Yes (fetch JD if no `jd_path`) |
| `jd_path` on row or user path | Preferred over re-fetch |
| Master resume at `profile.resume_path` | Yes (themes only) |

## Slug rules

Lowercase company and title; replace non-alphanumeric runs with `-`; collapse repeats.

Example: `Acme Corp` + `Product Manager` → `acme-corp-product-manager`.

Filename: `YYYY-MM-DD-{company-slug}-{title-slug}.md`. Same day + same company + same title: append `-2`, `-3`, etc.

## Workflow behavior

### 1. Load role context

Read tracker, config, resume themes. Load JD from `jd_path` or fetch `url` (browser for SPAs). Skip if idempotent re-run for today.

### 2. Research

Gather factual context from company site, news (12 months), listing. Record URLs for Sources section. Do not invent facts.

### 3. Run brief prompt

Substitute `{company}`, `{title}`, `{job_description}`, `{resume_themes}`, `{research_notes}`, `{output_language}`. Apply `prompt.md` verbatim. Markdown output only.

### 4. Save JD artifact

Write full JD to `data/jds/YYYY-MM-DD-{company-slug}-{title-slug}.md`:

```markdown
# {title} at {company}

**Source:** {canonical listing url}
**Saved:** YYYY-MM-DD

---

{full job description text}
```

Skip re-write if `jd_path` already points to this file. Copy external `jd_path` into `data/jds/` when needed.

### 5. Save role brief artifact

Write to `data/company-research/YYYY-MM-DD-{company-slug}-{title-slug}.md`.

### 6. Update tracker

Set `jd_path` and `company_research`. Optional notes append. Do not change `status`.

### 7. Present to user

Render brief; note JD and brief paths; remind to tailor and run `resume-feedback`.

## Brief sections (fixed headings in `prompt.md`)

| Section | Purpose |
|---------|---------|
| Snapshot | Company, title, location, fit tier |
| Company overview | Product, customers, stage (sourced only) |
| Role decode | Responsibilities, must/nice-to-have, team hints |
| Fit vs your profile | Alignment, gaps, industry flags |
| Application angle | Tailoring hooks, keywords, de-emphasize |
| Risks and open questions | Red flags, pre-apply questions |
| Sources consulted | URLs or "JD only" |

## Output principles

- Factual and neutral; mark unverified claims.
- Tie application angle to evidenced resume themes.
- Flag ⚠ industries from `industry_awareness.prefer_to_avoid`.
- No em dash characters in generated text.

## Trigger phrases

| Trigger | Action |
|---------|--------|
| `/company-research` | Run skill |
| "Brief on my shortlisted [Company] role" | Run with tracker context |
| Automatic on `shortlisted` | Via `update-application` or pipeline review |

## Testing and validation

- **Shortlist chain:** JD file exists; brief exists; tracker paths set; `git status` clean.
- **Idempotency:** Second run same day skips duplicate work.
- **Two roles same company:** Distinct `{title-slug}` filenames.
- **External jd_path:** Copied into `data/jds/`; row updated.

## Success criteria

1. Shortlisting produces JD cache + role brief without manual YAML edits.
2. `jd_path` is available for `resume-feedback` and `interview-prep`.
3. Brief is under ~800 words (unless JD is unusually long) and evidence-based.
4. Skill behavior matches this spec and `.cursor/skills/company-research/SKILL.md`.

## Future work (not v1.1)

| Item | Notes |
|------|-------|
| Re-fetch JD on listing change | Compare hash or `listing_verified` date |
| Obsidian sync | Optional vault path for briefs |
