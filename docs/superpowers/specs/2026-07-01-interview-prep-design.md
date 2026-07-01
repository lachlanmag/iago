# Interview Prep Skill: Design

## Goal

Add a Cursor-native **`interview-prep`** skill that builds interview talking points, STAR stories, and questions to ask from the full JD, master resume, and optional company role brief.

Runs automatically when an application is submitted (`applied` via `update-application`). No personal data committed to git.

## Scope

### In scope (v1.1)

- **`interview-prep` skill**: load context, verbatim prompt, save artifact, update tracker
- **`prompt.md`**: mandatory prep prompt with fixed markdown headings
- **Gitignored `data/interview-prep/`**: prep artifacts (`YYYY-MM-DD-{company-slug}-{title-slug}.md`)
- **JD source**: `jd_path` on tracker row (from `company-research`); re-fetch `url` if missing
- **Optional**: `company_research` brief for company context (not a JD substitute)
- **Idempotency**: skip if `interview_prep` on row points to today's artifact unless user requests refresh

### Out of scope (v1.1)

- Marking applied or scheduling interviews (`update-application`)
- Company research from scratch (run `company-research` if user wants)
- Mock interviews or salary negotiation
- Auto-updating tracker on follow-up reminders

### Relationship to existing workflow

```
company-research → jd_path + company_research artifact
update-application → applied
interview-prep     → data/interview-prep/ + interview_prep on row
```

## Architecture

**Approach:** Single skill + separate prompt file.

```
job-search/
  .cursor/skills/interview-prep/
    SKILL.md
    prompt.md
  data/                         # gitignored
    interview-prep/
      YYYY-MM-DD-{company-slug}-{title-slug}.md
  docs/superpowers/specs/
    2026-07-01-interview-prep-design.md
```

### Tracked vs local data

| Path | Git | Purpose |
|------|-----|---------|
| `.cursor/skills/interview-prep/` | tracked | Skill + prep prompt |
| `data/interview-prep/` | **ignored** | Prep artifacts |
| `data/jds/` | **ignored** | Full JD input via `jd_path` |

**Setup:** `scripts/init-data.sh` creates `data/interview-prep/`.

## Inputs

| Placeholder / source | Required |
|----------------------|----------|
| Tracker row (`id` or company + title) | Yes |
| JD (`jd_path` or re-fetch `url`) | Yes |
| Master resume at `profile.resume_path` | Yes |
| `company_research` artifact | Optional (`{company_brief}`) |
| `{output_language}` | User request, else config, else English |

## Slug rules

Same as `company-research`: `YYYY-MM-DD-{company-slug}-{title-slug}.md`. Duplicate same day: `-2`, `-3`, etc.

## Workflow behavior

### 1. Load context

Read tracker, config, resume. Load JD from `jd_path`; re-fetch listing if missing. Read company brief if `company_research` set.

### 2. Run prep prompt

Substitute `{company}`, `{title}`, `{job_description}`, `{resume_content}`, `{company_brief}`, `{output_language}`. Apply `prompt.md` verbatim. Markdown only.

### 3. Save artifact

Write `data/interview-prep/YYYY-MM-DD-{company-slug}-{title-slug}.md`.

### 4. Update tracker

Set `interview_prep` path. Do not change `status` unless user explicitly requested `interview`.

### 5. Present to user

Render key sections (elevator pitch, top STAR stories, likely questions, questions to ask). Note artifact path. Suggest polite follow-up after 14 days (do not auto-update tracker).

## Prep sections (fixed headings in `prompt.md`)

| Section | Purpose |
|---------|---------|
| Elevator pitch (60 seconds) | Spoken intro for this role |
| Why this role / why now | 3 alignment bullets |
| STAR story bank | 5 stories mapped to JD requirements |
| Likely interview questions | Recruiter, hiring manager, product sense |
| Gaps to address proactively | Honest framing without exaggeration |
| Questions to ask them | 8 tagged by stage |
| Day-before checklist | Practical prep tasks |

## Output principles

- STAR stories map to real resume bullets; flag weak evidence.
- Speakable answers (short paragraphs).
- 5-8 likely PM/PO/BA questions plus one product sense scenario.
- No em dash characters in generated text.

## Trigger phrases

| Trigger | Action |
|---------|--------|
| `/interview-prep` | Run skill |
| "Interview prep for [Company]" | Run with tracker context |
| Automatic on `applied` | Via `update-application` |
| Refresh on `interview` | When user asks or prep stale |

## Testing and validation

- **Apply chain:** Prep artifact saved; `interview_prep` set; uses `jd_path` content.
- **Missing jd_path:** Re-fetch from `url` succeeds or failure reported clearly.
- **Idempotency:** Same-day re-apply skips unless refresh requested.
- **Sanitization:** `git status` clean after run.

## Success criteria

1. Applying via `update-application` produces prep in the same session.
2. STAR stories reference evidenced resume content, not invented achievements.
3. Full JD used (from `jd_path` or fetch), not brief-only.
4. Skill behavior matches this spec and `.cursor/skills/interview-prep/SKILL.md`.

## Future work (not v1.1)

| Item | Notes |
|------|-------|
| Stage-specific prep | Recruiter vs HM vs panel variants |
| Calendar integration | Interview date on tracker row |
