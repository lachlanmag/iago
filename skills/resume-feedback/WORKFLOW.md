# Resume feedback

## When to use

- User wants HR-style feedback on a resume for a specific role (master or tailored)
- User asks for ATS readiness, keyword coverage, or tailoring quality review
- User says "review my resume", "review my tailored resume", "resume feedback", "ATS review for [Company]", "check my resume against the JD", "tailoring quality check", "is this resume ready to submit", `/iago-feedback`, or `/resume-feedback`
- After `company-research` on a shortlisted role, before applying
- After tailoring with Resume-Matcher (when `integrations.resume_matcher.enabled: true`)

**Not this skill:** master resume fit during search (use `iago-daily` / `iago-pipeline-review`), cover letters, or PDF export.

## Files (read as needed)

| File | Purpose |
|------|---------|
| `$REPO_ROOT/data/config.yaml` | `profile.output_language`, `profile.resume_path`, `integrations.resume_matcher.enabled` (default `false`) |
| `$REPO_ROOT/data/applications.yaml` | Optional: resolve company/title and JD path from a shortlisted role |
| `profile.resume_path` in config | Default resume source in standalone mode (read only; do not commit) |
| `$REPO_ROOT/skills/resume-feedback/prompt.md` | **Mandatory review prompt** (apply verbatim) |
| User-provided paths | Job description text/markdown; resume markdown or tailored JSON depending on mode (local; not in repo) |

## Inputs (required)

Collect before running the review:

| Placeholder | Source |
|-------------|--------|
| `{job_description}` | Full JD text: `jd_path` on tracker row, user paste, or local file path |
| `{resume_data}` | Resume content string (see mode table below) |
| `{output_language}` | User request, else `profile.output_language` in config, else `English` |

**Mode-aware resume resolution:**

| Config | Resume source | Format |
|--------|---------------|--------|
| `integrations.resume_matcher.enabled: true` | User path or inline JSON (required) | JSON |
| `false` or absent | `profile.resume_path` default; user override path or inline | markdown |

If any input is missing, ask once with concrete options (e.g. company from tracker, path to JD file, path to resume file or paste). Do not invent resume content or JD requirements.

**Placeholder substitution** (set before applying `$REPO_ROOT/skills/resume-feedback/prompt.md`):

| Placeholder | Matcher on | Matcher off |
|-------------|------------|-------------|
| `{resume_format}` | JSON | markdown |
| `{resume_source_label}` | Tailored Resume (JSON) | Resume (markdown) |
| `{parsability_note}` | note when format cannot be verified from JSON alone | note when format cannot be verified from markdown alone |

**Resume JSON (matcher on):** Use the file as provided. Do not convert from markdown unless the user asks. Pretty-print when substituting into the prompt if the file is minified.

**Resume markdown (matcher off):** Load from `profile.resume_path` unless the user supplies a path or inline paste. Do not convert to JSON.

**Tracker shortcut:** If the user names a shortlisted role, read `$REPO_ROOT/data/applications.yaml` for company/title and use `jd_path` when set (from `company-research`). Resolve resume per mode table above.

## Workflow

### 1. Resolve inputs

- Read `$REPO_ROOT/data/config.yaml` when present for `output_language` and `integrations.resume_matcher.enabled` (default `false`).
- Load `{job_description}` from `jd_path` on the tracker row when the user names a role; otherwise from user-supplied path or message.
- **Matcher on:** load `{resume_data}` from user-supplied path or inline JSON; pretty-print if minified. Ask once if missing.
- **Matcher off:** load `{resume_data}` from `profile.resume_path` unless the user overrides with path or inline markdown. Ask once if missing or unreadable.
- Record metadata for the report filename and artifact: `company`, `title`, `date` (today, `YYYY-MM-DD`), `resume_source` (resolved file path or `inline`), `resume_format` (`markdown` or `json`), `resume_matcher_enabled` (boolean).

### 2. Run the review

1. Open `$REPO_ROOT/skills/resume-feedback/prompt.md`.
2. Substitute `{output_language}`, `{job_description}`, `{resume_data}`, `{resume_format}`, `{resume_source_label}`, and `{parsability_note}`.
3. Apply the prompt **verbatim**. Do not shorten sections or change the required JSON shape.

### 3. Validate output

The model response must be **JSON only** with:

- `report_markdown`: full markdown report with headings exactly as specified in the prompt
- `questions`: array of 3 to 8 items with unique `question_id` (`q1`, `q2`, …) and `category` in `gap` | `risk` | `clarification` | `improvement` | `ats`

If the response includes markdown fences or prose outside JSON, extract or re-run until valid JSON is produced.

### 4. Save feedback artifact

Write:

`$REPO_ROOT/data/resume-feedback/YYYY-MM-DD-{company-slug}-{title-slug}.json`

**Slugs:** same rules as `company-research` (`{company-slug}-{title-slug}`). Same day + same company + same title: append `-2`, `-3`, etc.

JSON file shape:

```json
{
  "meta": {
    "company": "",
    "title": "",
    "reviewed": "YYYY-MM-DD",
    "output_language": "",
    "resume_source": "",
    "resume_format": "markdown",
    "resume_matcher_enabled": false
  },
  "report_markdown": "",
  "questions": []
}
```

`resume_format` is `markdown` or `json`. `resume_source` is the resolved file path or `inline`. `meta` wraps the review prompt output for local tracking. Do not commit personal data; `data/` is gitignored.

### 5. Present to user

In chat:

1. Render `report_markdown` as readable markdown (headings and lists intact).
2. Add a short **Questions for you** subsection listing `questions` as a numbered list (`prompt`; include `context` when present).
3. Note the saved path under `$REPO_ROOT/data/resume-feedback/`.

### 6. Optional follow-up

If the user answers clarification questions, offer to re-run feedback on an updated resume (path or paste) or to update `resume_status` in `$REPO_ROOT/data/applications.yaml` when they confirm apply-ready.

## Output principles

- Evidence-based and neutral; no invented experience or metrics.
- Flag JD mirroring and unsupported tailoring claims explicitly.
- ATS recommendations must tie keywords to evidenced experience; mark unverified items for candidate confirmation.
- No em dash characters in generated report text (per prompt).

## Manual commands

**Standalone (default; uses `profile.resume_path`):**

> /resume-feedback

> Resume feedback for my shortlisted [Company] role

> Review my resume for [Company]. JD at [path]

**With Resume-Matcher (`integrations.resume_matcher.enabled: true`):**

> Resume feedback for [Company]. JD at [path], tailored resume JSON at [path]

> ATS feedback on this tailored resume for the [title] role at [company]

## Out of scope

- Tailoring or rewriting the resume (feedback only unless user asks for edits in a separate turn)
- Submitting applications or updating tracker status without user confirmation
- Searching for new job listings
