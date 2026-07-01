---
name: interview-prep
description: >-
  Build interview talking points, STAR stories, and questions to ask from the JD,
  resume, and any company brief. Runs automatically when an application is
  submitted (status applied via update-application). Use when the user applies,
  asks for interview prep, talking points, or runs /interview-prep.
---

# Interview prep

## When to use

- **Automatic:** Immediately after a role's status is set to `applied` in `data/applications.yaml` (same session; do not ask permission to run).
- User moves to `interview` status and asks for refreshed prep.
- User says "interview prep for [Company]", "talking points for [role]", or `/interview-prep`.

**Not this skill:** pre-apply role brief (use `company-research`), resume feedback (use `resume-feedback`), new job search.

## Files (read as needed)

| File | Purpose |
|------|---------|
| `data/applications.yaml` | Applied role row (`company_research`, `jd_path`, notes) |
| `data/config.yaml` | `profile.resume_path`, `profile.output_language` |
| `profile.resume_path` in config | Master resume for STAR stories |
| `data/jds/*.md` | Full JD cached on shortlist (`jd_path` on row) |
| `data/company-research/*.md` | Optional brief if `company_research` set on row |
| [prompt.md](prompt.md) | **Mandatory prep prompt** (apply verbatim) |

Repo root is the Cursor workspace.

## Inputs (resolve before prep)

| Source | Required |
|--------|----------|
| Tracker row (`id` or company + title) | Yes |
| JD (`jd_path` on row, or re-fetch canonical `url`) | Yes |
| Master resume at `profile.resume_path` | Yes |
| `company_research` artifact | Use when present |

For automatic runs, the row must be `applied` (with `applied: YYYY-MM-DD`) after the tracker write.

Skip if `interview_prep` on the row points to an artifact dated today for this tracker row unless user asks for a refresh.

## Workflow

### 1. Load context

- Read tracker row, config, and master resume.
- Load JD from `jd_path` on the row (set by `company-research` on shortlist). If missing, re-fetch listing `url`.
- If `company_research` path is set, read that brief for company/role context (not a substitute for the full JD).

### 2. Run the prep prompt

1. Open [prompt.md](prompt.md).
2. Substitute `{company}`, `{title}`, `{job_description}`, `{resume_content}`, `{company_brief}`, `{output_language}`.
3. Apply **verbatim**. Output is markdown only.

`{company_brief}`: summary section from company-research file, or "Not available".
`{output_language}`: user request, else config, else `English`.

Use resume content for story mining only. Do not invent achievements.

### 3. Save artifact

Write:

`data/interview-prep/YYYY-MM-DD-{company-slug}-{title-slug}.md`

**Slugs:** same rules as `company-research` (`{company-slug}-{title-slug}`). Same day + same company + same title: append `-2`, `-3`, etc.

### 4. Update tracker

On the application row, set:

- `interview_prep: data/interview-prep/YYYY-MM-DD-{company-slug}-{title-slug}.md`

Do not change `status` unless user explicitly requested `interview`.

### 5. Present to user

In chat:

1. Lead with **Interview prep ready** for company + title.
2. Render key sections: elevator pitch, top 3 STAR stories, likely questions, questions to ask them.
3. Note full artifact path.
4. If no response after 14 days, suggest a polite follow-up (one line); do not auto-update tracker.

## Output principles

- STAR stories must map to real resume bullets; flag weak evidence.
- Answers should be speakable (short paragraphs, not essay tone).
- Include 5–8 likely questions for PM/PO/BA screens and one deeper product sense question.
- No em dash characters in generated text.
- Personal artifacts stay under gitignored `data/`.

## Manual commands

> /interview-prep

> Interview prep for my application at [Company]

> Refresh interview prep for [Company]. I have an interview next week

## Out of scope

- Marking applied or scheduling interviews (`update-application`)
- Company research from scratch (run `company-research` if missing and user wants it)
- Mock interviews or salary negotiation
