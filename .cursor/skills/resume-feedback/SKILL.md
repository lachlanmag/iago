---
name: resume-feedback
description: >-
  Review a tailored resume JSON against a job description for role fit, ATS
  readiness, and hiring recommendation. Use when the user asks for resume
  feedback, ATS review, tailoring quality check, hiring review of a tailored
  resume, or runs /resume-feedback.
disable-model-invocation: true
---

# Resume feedback

## When to use

- User wants HR-style feedback on a **tailored** resume for a specific role
- User asks for ATS readiness, keyword coverage, or tailoring quality review
- User says "review my tailored resume", "resume feedback", or `/resume-feedback`
- After tailoring (e.g. Resume-Matcher) before submitting an application

**Not this skill:** master resume fit during search (use `job-search-daily` / `job-search-pipeline-review`), cover letters, or PDF export.

## Files (read as needed)

| File | Purpose |
|------|---------|
| `data/config.yaml` | Optional `profile.output_language` (default review language) |
| `data/applications.yaml` | Optional: resolve company/title and JD path from a shortlisted role |
| [prompt.md](prompt.md) | **Mandatory review prompt** (apply verbatim) |
| User-provided paths | Job description text/markdown and tailored resume JSON (local; not in repo) |

Repo root is the Cursor workspace. Paths below are relative to repo root.

## Inputs (required)

Collect before running the review:

| Placeholder | Source |
|-------------|--------|
| `{job_description}` | Full JD text: `jd_path` on tracker row, user paste, or local file path |
| `{resume_data}` | Tailored resume as JSON string (file path or inline JSON) |
| `{output_language}` | User request, else `profile.output_language` in config, else `English` |

If any input is missing, ask once with concrete options (e.g. company from tracker, path to JD file, path to resume JSON). Do not invent resume content or JD requirements.

**Resume JSON:** Use the file as provided. Do not convert from markdown unless the user asks. Pretty-print when substituting into the prompt if the file is minified.

**Tracker shortcut:** If the user names a shortlisted role, read `data/applications.yaml` for company/title and use `jd_path` when set (from `company-research`). Still require tailored resume JSON (from path the user provides unless given inline).

## Workflow

### 1. Resolve inputs

- Read `data/config.yaml` when present for `output_language`.
- Load `{job_description}` from `jd_path` on the tracker row when the user names a role; otherwise from user-supplied path or message.
- Load `{resume_data}` from user-supplied path or message.
- Record metadata for the report filename: `company`, `title`, `date` (today, `YYYY-MM-DD`).

### 2. Run the review

1. Open [prompt.md](prompt.md).
2. Substitute `{output_language}`, `{job_description}`, and `{resume_data}`.
3. Apply the prompt **verbatim**. Do not shorten sections or change the required JSON shape.

### 3. Validate output

The model response must be **JSON only** with:

- `report_markdown`: full markdown report with headings exactly as specified in the prompt
- `questions`: array of 3 to 8 items with unique `question_id` (`q1`, `q2`, …) and `category` in `gap` | `risk` | `clarification` | `improvement` | `ats`

If the response includes markdown fences or prose outside JSON, extract or re-run until valid JSON is produced.

### 4. Save feedback artifact

Write:

`data/resume-feedback/YYYY-MM-DD-{company-slug}-{title-slug}.json`

**Slugs:** same rules as `company-research` (`{company-slug}-{title-slug}`). Same day + same company + same title: append `-2`, `-3`, etc.

JSON file shape:

```json
{
  "meta": {
    "company": "",
    "title": "",
    "reviewed": "YYYY-MM-DD",
    "output_language": ""
  },
  "report_markdown": "",
  "questions": []
}
```

`meta` wraps the review prompt output for local tracking. Do not commit personal data; `data/` is gitignored.

### 5. Present to user

In chat:

1. Render `report_markdown` as readable markdown (headings and lists intact).
2. Add a short **Questions for you** subsection listing `questions` as a numbered list (`prompt`; include `context` when present).
3. Note the saved path under `data/resume-feedback/`.

### 6. Optional follow-up

If the user answers clarification questions, offer to re-run feedback on an updated resume JSON or to update `resume_status` in `data/applications.yaml` when they confirm apply-ready.

## Output principles

- Evidence-based and neutral; no invented experience or metrics.
- Flag JD mirroring and unsupported tailoring claims explicitly.
- ATS recommendations must tie keywords to evidenced experience; mark unverified items for candidate confirmation.
- No em dash characters in generated report text (per prompt).

## Manual commands

**Run in chat:**

> /resume-feedback

> Review my tailored resume for [Company]. JD at [path], resume JSON at [path]

> ATS feedback on this resume for the [title] role at [company]

**With tracker context:**

> Resume feedback for my shortlisted [Company] role. JD: [path], tailored resume: [path]

## Out of scope

- Tailoring or rewriting the resume (feedback only unless user asks for edits in a separate turn)
- Submitting applications or updating tracker status without user confirmation
- Searching for new job listings
