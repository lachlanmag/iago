# Resume Feedback Skill: Design

## Goal

Add a Cursor-native **`resume-feedback`** skill that reviews a **tailored resume JSON** against a **specific job description** and produces structured HR-style feedback: role fit, ATS readiness, tailoring quality, hiring recommendation, and follow-up questions for the candidate.

The skill closes the gap between external resume tailoring (e.g. Resume-Matcher) and submitting an application. It does not tailor resumes or submit applications.

No personal resume content, job descriptions, or feedback artifacts are committed to git.

## Scope

### In scope (v1.1)

- **`resume-feedback` skill**: input resolution, verbatim prompt application, JSON validation, artifact save, chat presentation
- **`prompt.md`**: mandatory review prompt with fixed markdown headings and JSON output shape
- **Gitignored `data/resume-feedback/`**: local feedback artifacts (`YYYY-MM-DD-{company-slug}-{title-slug}.json`)
- **Optional tracker context**: resolve company/title from `data/applications.yaml` when user names a shortlisted role
- **Optional config hook**: `profile.output_language` in `data/config.yaml` for review language (default: English)
- **README and ROADMAP updates**: document the skill, trigger phrases, and artifact path

### Out of scope (v1.1)

- Resume tailoring, rewriting, or PDF export (feedback only unless user asks for edits in a separate turn)
- Master resume fit scoring during search (remains `iago-daily` / `iago-pipeline-review`)
- Cover letter review
- Automatic tracker updates (`resume_status`, status changes) without user confirmation
- Headless CLI script (chat-triggered only, like pipeline review)
- Searching for new job listings
- Committing example feedback artifacts (personal data)

### Relationship to existing workflow

```
iago-daily           → discover + score vs master resume
iago-pipeline-review → triage + prioritize shortlist
update-application         → shortlist (chains company-research)
[external tailoring]       → tailored resume JSON (user's tool, outside repo)
resume-feedback            → review tailored JSON vs JD before apply
update-application         → apply (chains interview-prep)
```

Resume tooling stays outside the repo. The skill accepts user-provided paths to JD text and tailored resume JSON.

## Architecture

**Approach:** Single skill + separate prompt file (mirrors `iago-pipeline-review` pattern: workflow in `SKILL.md`, no scripts).

```
iago/
  .cursor/skills/resume-feedback/
    SKILL.md              # Workflow, inputs, validation, artifact save
    prompt.md             # Mandatory review prompt (substitute placeholders)
  data/                   # gitignored
    resume-feedback/
      YYYY-MM-DD-{company-slug}-{title-slug}.json
  docs/superpowers/specs/
    2026-07-01-resume-feedback-design.md
```

### Tracked vs local data

| Path | Git | Purpose |
|------|-----|---------|
| `.cursor/skills/resume-feedback/` | tracked | Skill definition and review prompt |
| `data/resume-feedback/` | **ignored** | Feedback artifacts per company/review |
| User-provided JD and resume JSON | **outside repo or gitignored** | Inputs; never committed |

**Setup:** `scripts/init-data.sh` creates `data/resume-feedback/` alongside other artifact directories.

## Inputs

Collect before running the review. If any required input is missing, ask once with concrete options. Do not invent resume content or JD requirements.

| Placeholder | Source | Required |
|-------------|--------|----------|
| `{job_description}` | Full JD text: `jd_path` on tracker row, user paste, or local file path | Yes |
| `{resume_data}` | Tailored resume as JSON string (file path or inline JSON) | Yes |
| `{output_language}` | User request, else `profile.output_language` in config, else `English` | Yes (defaulted) |

**Metadata for artifact filename:** `company`, `title`, `date` (today, `YYYY-MM-DD`). From user input or `applications.yaml` when user names a shortlisted role.

**Resume JSON:** Use the file as provided. Do not convert from markdown unless the user asks. Pretty-print when substituting into the prompt if the file is minified.

**Tracker shortcut:** If the user names a shortlisted role, read `data/applications.yaml` for company/title and use `jd_path` when set (from `company-research`). Still require tailored resume JSON from path the user provides.

## Workflow behavior

### 1. Resolve inputs

- Read `data/config.yaml` when present for `output_language`.
- Load `{job_description}` and `{resume_data}` from user-supplied paths or message.
- Record metadata: company, title, date.

### 2. Run the review

1. Open `prompt.md`.
2. Substitute `{output_language}`, `{job_description}`, and `{resume_data}`.
3. Apply the prompt **verbatim**. Do not shorten sections or change the required JSON shape.

### 3. Validate output

Model response must be **JSON only** with:

- `report_markdown`: full markdown report with headings exactly as specified in the prompt
- `questions`: array of 3 to 8 items with unique `question_id` (`q1`, `q2`, …) and `category` in `gap` | `risk` | `clarification` | `improvement` | `ats`

If the response includes markdown fences or prose outside JSON, extract or re-run until valid JSON is produced.

### 4. Save feedback artifact

Write:

`data/resume-feedback/YYYY-MM-DD-{company-slug}-{title-slug}.json`

Use `{company-slug}-{title-slug}` (same slug rules as `company-research`). If multiple reviews same day for the same company and title, append `-2`, `-3`, etc.

### 5. Present to user

In chat:

1. Render `report_markdown` as readable markdown (headings and lists intact).
2. Add a short **Questions for you** subsection listing `questions` as a numbered list (`prompt`; include `context` when present).
3. Note the saved path under `data/resume-feedback/`.

### 6. Optional follow-up

If the user answers clarification questions, offer to re-run feedback on an updated resume JSON or to update `resume_status` in `data/applications.yaml` when they confirm apply-ready.

## Data model

### Feedback artifact (`data/resume-feedback/YYYY-MM-DD-{company-slug}-{title-slug}.json`)

```json
{
  "meta": {
    "company": "",
    "title": "",
    "reviewed": "YYYY-MM-DD",
    "output_language": ""
  },
  "report_markdown": "",
  "questions": [
    {
      "question_id": "q1",
      "category": "gap",
      "prompt": "",
      "context": ""
    }
  ]
}
```

`meta` wraps the review prompt output for local tracking and re-reads. `context` on questions is optional.

### Report sections (fixed headings in `prompt.md`)

| Section | Purpose |
|---------|---------|
| Candidate summary | 3–5 bullets on fit for this specific role |
| Strengths | Evidence-backed signals from resume |
| Concerns or gaps | Missing signals, vague claims, JD mirroring without proof |
| Tailoring quality | Strong/weak tailoring, keyword stuffing risk, unsupported claims |
| Role fit score | 1–10 subscores + overall with rationale |
| ATS assessment | Readiness score, parsability checks, keyword coverage/quality, seniority alignment, top blockers |
| ATS optimization recommendations | Issue / Fix / Priority; evidence-backed only |
| Hiring recommendation | Strong yes / Yes / Maybe / No with reason |
| Interview focus areas | 5–8 validation questions |
| Resume improvement suggestions | Concrete edits (non-duplicative of ATS list) |
| Gaps and questions for the candidate | 3–8 items; some may appear in `questions` array |

### Optional config extension

Add to `examples/config.example.yaml` under `profile`:

```yaml
output_language: English  # optional; language for resume-feedback reports
```

Not required for v1.1 ship; skill defaults to English when absent.

## Output principles

- Evidence-based and neutral; no invented experience or metrics.
- Flag JD mirroring and unsupported tailoring claims explicitly.
- ATS recommendations must tie keywords to evidenced experience; mark unverified items for candidate confirmation.
- No em dash characters in generated report text (per prompt and workspace rule).

## Trigger phrases

| Trigger | Action |
|---------|--------|
| `/resume-feedback` | Run skill |
| "Review my tailored resume for [Company]" | Run with named role |
| "ATS feedback on this resume for the [title] role at [company]" | Run with ATS focus |
| "Resume feedback for my shortlisted [Company] role" | Load tracker context + user paths |

**Not this skill:** master resume fit during search, cover letters, PDF export, new job search.

## Documentation updates (implementation)

| File | Change | Status |
|------|--------|--------|
| `README.md` | Apply workflow section, resume-feedback triggers, repo layout and `data/` table | Done |
| `docs/ROADMAP.md` | Mark `resume-feedback` as shipped; note in apply workflow | Done |
| `scripts/init-data.sh` | `mkdir -p "$DATA/resume-feedback"` | Done |
| `examples/config.example.yaml` | `profile.output_language` | Done |
| `docs/superpowers/specs/2026-06-26-iago-workflow-design.md` | Cross-link shipped application workflow skills | Done |

## Testing and validation

- **Manual:** Run skill with a real shortlisted role, JD file, and tailored resume JSON; confirm artifact path, valid JSON shape, and `git status` shows no changes under `data/`.
- **Output check:** Verify all prompt headings appear in `report_markdown`; `questions` length 3–8 with valid categories.
- **Edge cases:** Missing inputs (skill asks once); minified JSON (pretty-print on substitute); duplicate same-day review (slug suffix); invalid model output (re-run until JSON-only).
- **Sanitization:** No example feedback files in repo; skill does not read or write committed resume content.

## Success criteria

1. After tailoring externally, a user can run `/resume-feedback` with JD + tailored JSON paths and get a structured report in chat plus a saved artifact under `data/resume-feedback/`.
2. `git status` shows no personal data after a full feedback run.
3. Feedback is role-specific (not generic PM advice) and flags unsupported tailoring claims.
4. README documents the skill and its place in the apply workflow.
5. Skill behavior matches this spec and `.cursor/skills/resume-feedback/SKILL.md`.

## Future work (not v1.1)

| Item | Notes |
|------|-------|
| `update-application` integration | Set `resume_status: ready` after user confirms apply-ready (tracked in ROADMAP Later #16) |
| Headless script | Only if feedback runs become scheduled/batch |
| Resume-Matcher hook docs | Document expected JSON shape for handoff ([#3](https://github.com/lachlanmag/iago/issues/3)) |
| Re-run diff | Compare two feedback artifacts for same role after resume edits |

---

## v1.2: Standalone mode (no Resume-Matcher)

**Status:** Approved 2026-07-01. Approach 1: config flag + prompt placeholders. Default: Resume-Matcher off.

### Goal

Make `resume-feedback` usable without Resume-Matcher or any external tailoring tool. When Resume-Matcher is disabled (the default), the skill reviews markdown from `profile.resume_path` or a user override path. When enabled, behavior matches v1.1 (tailored resume JSON handoff).

### Scope (v1.2)

**In scope:**

- `integrations.resume_matcher.enabled` in `data/config.yaml` (default `false` when absent)
- Mode-aware input resolution in `SKILL.md`
- Prompt placeholders for format-specific wording (single `prompt.md`, same report structure)
- Extended artifact `meta` (`resume_source`, `resume_format`, `resume_matcher_enabled`)
- README and `company-research` reminder updates for both paths

**Out of scope:**

- Markdown-to-JSON conversion
- Resume tailoring or rewriting
- Resume-Matcher hook docs (ROADMAP #12)
- Tracker `resume_status` automation

### Config

Add to `examples/config.example.yaml`:

```yaml
integrations:
  resume_matcher:
    enabled: false  # true when using Resume-Matcher for tailoring handoff
```

| Value | Resume input | Default source | Format |
|-------|--------------|----------------|--------|
| `false` or absent | Markdown | `profile.resume_path` | User override path or inline paste optional |
| `true` | Tailored JSON | User-provided path or inline (required) | Pretty-print if minified |

When `enabled: false` and `profile.resume_path` is missing or unreadable, ask once for a resume path or paste.

### Workflow paths

**Standalone (default):**

```
shortlist → company-research → resume-feedback (master or tailored markdown) → apply → interview-prep
```

**With Resume-Matcher (`enabled: true`):**

```
shortlist → company-research → [Resume-Matcher] → resume-feedback (JSON) → apply → interview-prep
```

### Prompt placeholders

Substitute in `prompt.md` before applying verbatim (in addition to v1.1 placeholders):

| Placeholder | Matcher on | Matcher off |
|-------------|------------|-------------|
| `{resume_format}` | `JSON` | `markdown` |
| `{resume_source_label}` | `Tailored Resume (JSON)` | `Resume (markdown)` |
| `{parsability_note}` | `note when format cannot be verified from JSON alone` | `note when format cannot be verified from markdown alone` |

Replace hard-coded "JSON" references in the prompt body with these placeholders. Report headings, scoring rubric, and JSON output shape are unchanged.

### Artifact `meta` (v1.2)

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
  }
}
```

`resume_format` is `markdown` or `json`. `resume_source` is the resolved file path or `inline`.

### Documentation updates (v1.2)

| File | Change |
|------|--------|
| `.cursor/skills/resume-feedback/SKILL.md` | Mode-aware input resolution and placeholder substitution |
| `.cursor/skills/resume-feedback/prompt.md` | Format placeholders |
| `examples/config.example.yaml` | `integrations.resume_matcher.enabled` |
| `README.md` | Standalone vs Matcher apply paths |
| `.cursor/skills/company-research/SKILL.md` | Mode-aware post-brief reminder |

### Testing and validation (v1.2)

- **Standalone:** `enabled: false` (or absent), shortlisted role with `jd_path`, only `profile.resume_path` set; confirm report + artifact with `resume_format: markdown`.
- **Matcher:** `enabled: true`, tailored JSON path; confirm behavior matches v1.1 and `resume_format: json`.
- **Override:** Standalone mode with user-provided tailored markdown path; confirm `resume_source` reflects override.
- **Edge:** Standalone with missing `resume_path`; skill asks once.
- **Sanitization:** `git status` clean after runs.

### Success criteria (v1.2)

1. With `resume_matcher.enabled: false` (or absent) and only `profile.resume_path` set, `/resume-feedback` for a shortlisted role runs without JSON or Resume-Matcher.
2. With `enabled: true`, behavior matches v1.1 (JSON required, Matcher-oriented wording).
3. Same report structure and artifact path in both modes.
4. README documents both workflow paths.
