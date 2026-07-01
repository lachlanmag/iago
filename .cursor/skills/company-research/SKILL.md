---
name: company-research
description: >-
  Produce a role brief for a shortlisted job from the listing, company site, and
  tracker context. Runs automatically when a role is promoted to shortlisted
  (via update-application or pipeline-review). Use when the user shortlists a
  role, asks for a company brief, role brief, or runs /company-research.
---

# Company research (role brief)

## When to use

- **Automatic:** Immediately after a role's status is set to `shortlisted` in `data/applications.yaml` (same session; do not ask permission to run).
- User asks for a company or role brief before tailoring or applying.
- User says "research [Company]", "brief on this role", or `/company-research`.

**Not this skill:** interview talking points after apply (use `interview-prep`), resume tailoring feedback (use `resume-feedback`), new job search (use `job-search-daily`).

## Files (read as needed)

| File | Purpose |
|------|---------|
| `data/applications.yaml` | Shortlisted role row (company, title, url, industry, resume_fit, notes) |
| `data/config.yaml` | `profile.resume_path`, industry awareness, resume fit themes |
| `profile.resume_path` in config | Master resume for fit angle (read only; do not commit) |
| User `jd_path` on tracker row | Saved JD markdown if already set (external or `data/jds/`) |
| `data/jds/` | Full job descriptions cached on shortlist (gitignored) |
| [prompt.md](prompt.md) | **Mandatory brief prompt** (apply verbatim after research) |

Repo root is the Cursor workspace. Paths below are relative to repo root.

## Inputs (resolve before research)

| Source | Required |
|--------|----------|
| Tracker row (`id` or company + title) | Yes |
| Canonical listing `url` | Yes: fetch JD if no `jd_path` |
| `jd_path` on row or user-provided path | Preferred over re-fetch when present |
| Master resume at `profile.resume_path` | Yes: for fit angle only |

If the role is not `shortlisted` (or being promoted in the same turn), still run when explicitly requested. For automatic runs, the row must be `shortlisted` after the tracker write.

## Workflow

### 1. Load role context

- Read the tracker row and `data/config.yaml`.
- Read master resume at `profile.resume_path` (themes only; do not quote long passages).
- Load JD from `jd_path` if set; otherwise open canonical `url` and extract the full job description. Use browser for SPAs that block fetch.
- Skip if `company_research` on the row points to an artifact dated today for this tracker row (idempotent re-run). Otherwise proceed.

### 2. Research (web + listing)

Gather **factual** context only. Do not invent funding, headcount, or product details.

| Area | Sources |
|------|---------|
| Company | Official site (about, product, careers), recent news (last 12 months), LinkedIn company page if needed |
| Role | Listing JD, hiring manager or team hints in posting |
| Market | One paragraph on category/competitors if easily verifiable |

Record URLs consulted for the **Sources** section.

### 3. Run the brief prompt

1. Open [prompt.md](prompt.md).
2. Substitute `{company}`, `{title}`, `{job_description}`, `{resume_themes}`, `{research_notes}`, and `{output_language}`.
3. Apply the prompt **verbatim**. Output is markdown only (no JSON wrapper).

`{output_language}`: user request, else `profile.output_language` in config, else `English`.

### 4. Save JD artifact

Write the **full** job description (verbatim from listing or existing `jd_path` source) to:

`data/jds/YYYY-MM-DD-{company-slug}-{title-slug}.md`

**Slugs:** same rules as the role brief (`{company-slug}-{title-slug}`).

File shape:

```markdown
# {title} at {company}

**Source:** {canonical listing url}
**Saved:** YYYY-MM-DD

---

{full job description text}
```

- If `jd_path` already points to this `data/jds/` file for the role, skip re-write.
- If `jd_path` points elsewhere, copy content into `data/jds/…` and update the row to the new path.
- If JD was fetched from `url`, save extracted text to `data/jds/…`.

### 5. Save role brief artifact

Write:

`data/company-research/YYYY-MM-DD-{company-slug}-{title-slug}.md`

**Slugs:** lowercase company and title; replace non-alphanumeric runs with `-`; collapse repeats (e.g. `Acme Corp` + `Product Manager` → `acme-corp-product-manager`). Same day + same company + same title: append `-2`, `-3`, etc.

### 6. Update tracker

On the application row, set:

- `jd_path: data/jds/YYYY-MM-DD-{company-slug}-{title-slug}.md` (when saved or copied this run)
- `company_research: data/company-research/YYYY-MM-DD-{company-slug}-{title-slug}.md`
- Optional `notes` append: `Brief saved YYYY-MM-DD`

Do not change `status` or other fields.

### 7. Present to user

In chat:

1. Lead with **Role brief ready** and the company + title.
2. Render the saved markdown (headings intact).
3. Note paths for the role brief and saved JD (`jd_path`), then remind to tailor resume and run `resume-feedback` before applying.

## Output principles

- Factual and neutral; mark uncertain claims as unverified.
- Tie **application angle** to evidenced resume themes, not wishful fit.
- Flag ⚠ industries from `industry_awareness.prefer_to_avoid` when relevant.
- No em dash characters in generated text.
- Do not commit personal data; `data/` is gitignored.

## Manual commands

> /company-research

> Brief on my shortlisted [Company] role

> Research [Company] for the [title] role. JD at [path]

## Out of scope

- Updating status to `shortlisted` (caller: `update-application` or `job-search-pipeline-review`)
- Resume tailoring or ATS review
- Interview prep (use `interview-prep` after apply)
