# Company research (role brief)

## When to use

- **Automatic:** Immediately after a role's status is set to `shortlisted` in `$REPO_ROOT/data/applications.yaml` (same session; do not ask permission to run).
- User asks for a company or role brief before tailoring or applying.
- User says "research [Company]", "company brief for [Company]", "role brief for [Company]", "brief on this role", "tell me about [Company] for this role", "prep a brief before I apply", `/iago-brief`, or `/company-research`.

**Not this skill:** interview talking points after apply (use `interview-prep`), resume tailoring feedback (use `resume-feedback`), new job search (use `iago-daily`).

## Files (read as needed)

| File | Purpose |
|------|---------|
| `$REPO_ROOT/data/applications.yaml` | Shortlisted role row (company, title, url, industry, resume_fit, notes) |
| `$REPO_ROOT/data/config.yaml` | `profile.resume_path`, industry awareness, resume fit themes |
| `profile.resume_path` in config | Master resume for fit angle (read only; do not commit) |
| User `jd_path` on tracker row | Saved JD markdown if already set (external or `$REPO_ROOT/data/jds/`) |
| `$REPO_ROOT/data/jds/` | Full job descriptions cached on shortlist (gitignored) |
| `$REPO_ROOT/skills/company-research/prompt.md` | **Mandatory brief prompt** (apply verbatim after research) |

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

- Read the tracker row and `$REPO_ROOT/data/config.yaml`.
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

1. Open `$REPO_ROOT/skills/company-research/prompt.md`.
2. Substitute `{company}`, `{title}`, `{job_description}`, `{resume_themes}`, `{research_notes}`, and `{output_language}`.
3. Apply the prompt **verbatim**. Output is markdown only (no JSON wrapper).

`{output_language}`: user request, else `profile.output_language` in config, else `English`.

### 4. Save JD artifact

Write the **full** job description (verbatim from listing or existing `jd_path` source) to:

`$REPO_ROOT/data/jds/YYYY-MM-DD-{company-slug}-{title-slug}.md`

**Slugs:** same rules as the role brief (`{company-slug}-{title-slug}`).

File shape:

```markdown
# {title} at {company}

**Source:** {canonical listing url}
**Saved:** YYYY-MM-DD

---

{full job description text}
```

- If `jd_path` already points to this `$REPO_ROOT/data/jds/` file for the role, skip re-write.
- If `jd_path` points elsewhere, copy content into `$REPO_ROOT/data/jds/…` and update the row to the new path.
- If JD was fetched from `url`, save extracted text to `$REPO_ROOT/data/jds/…`.

### 5. Save role brief artifact

Write:

`$REPO_ROOT/data/company-research/YYYY-MM-DD-{company-slug}-{title-slug}.md`

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
3. Note paths for the role brief and saved JD (`jd_path`), then remind about next steps before applying (read `integrations.resume_matcher.enabled` from `$REPO_ROOT/data/config.yaml`, default `false`):
   - **Matcher off (default):** run `resume-feedback` on master or tailored markdown before applying.
   - **Matcher on:** tailor via Resume-Matcher, then run `resume-feedback` on the JSON output.

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

- Updating status to `shortlisted` (caller: `update-application` or `iago-pipeline-review`)
- Resume tailoring or ATS review
- Interview prep (use `interview-prep` after apply)
