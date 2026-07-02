# Resume Feedback Standalone Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `integrations.resume_matcher.enabled` config (default off) so `resume-feedback` works with master markdown from `profile.resume_path` without Resume-Matcher, while preserving v1.1 JSON handoff when enabled.

**Architecture:** Single `prompt.md` with format placeholders substituted by the skill based on config. `SKILL.md` branches input resolution only; report structure and artifact shape stay the same.

**Tech Stack:** Cursor skills (markdown), `data/config.yaml`, gitignored artifacts.

**Spec:** [2026-07-01-resume-feedback-design.md](../specs/2026-07-01-resume-feedback-design.md) (v1.2 section)

---

### Task 1: Add integration config to example

**Files:**
- Modify: `examples/config.example.yaml`

- [ ] **Step 1: Add `integrations` block after `profile`**

Insert after the `profile:` block (before `role_priority:`):

```yaml
integrations:
  resume_matcher:
    enabled: false  # true when using Resume-Matcher for tailoring handoff
```

- [ ] **Step 2: Update `output_language` comment**

Change the `output_language` line comment to remain accurate (no change needed if it already lists resume-feedback).

- [ ] **Step 3: Verify YAML parses**

Run: `python3 -c "import yaml; yaml.safe_load(open('examples/config.example.yaml'))"`
Expected: no output (success)

- [ ] **Step 4: Commit**

```bash
git add examples/config.example.yaml
git commit -m "feat: add resume_matcher integration flag to config example"
```

---

### Task 2: Add prompt placeholders

**Files:**
- Modify: `.cursor/skills/resume-feedback/prompt.md`

- [ ] **Step 1: Replace format-specific wording**

Apply these replacements in `prompt.md`:

Line 5, change:
```
Evaluate only what is in the resume JSON below.
```
to:
```
Evaluate only what is in the resume {resume_format} below.
```

Line 10-11, change:
```
Tailored Resume (JSON):
{resume_data}
```
to:
```
{resume_source_label}:
{resume_data}
```

Line 58, change:
```
(note when format cannot be verified from JSON alone):
```
to:
```
({parsability_note}):
```

- [ ] **Step 2: Verify placeholders**

Run: `grep -E '\{resume_format\}|\{resume_source_label\}|\{parsability_note\}' .cursor/skills/resume-feedback/prompt.md`
Expected: three matches

- [ ] **Step 3: Commit**

```bash
git add .cursor/skills/resume-feedback/prompt.md
git commit -m "feat: add format placeholders to resume-feedback prompt"
```

---

### Task 3: Update resume-feedback skill workflow

**Files:**
- Modify: `.cursor/skills/resume-feedback/SKILL.md`

- [ ] **Step 1: Update frontmatter description**

Change description to mention standalone markdown and optional Resume-Matcher JSON (not JSON-only).

- [ ] **Step 2: Update Files table**

Add `integrations.resume_matcher.enabled` to config row. Change user-provided paths row to cover markdown or JSON depending on mode.

- [ ] **Step 3: Replace Inputs section**

Document mode-aware resolution:

| Config | Resume source | Format |
|--------|---------------|--------|
| `integrations.resume_matcher.enabled: true` | User path or inline JSON (required) | JSON |
| `false` or absent | `profile.resume_path` default; user path or inline override | markdown |

Keep `{job_description}` and `{output_language}` unchanged from v1.1.

Add placeholder substitution table:

| Placeholder | Matcher on | Matcher off |
|-------------|------------|-------------|
| `{resume_format}` | `JSON` | `markdown` |
| `{resume_source_label}` | `Tailored Resume (JSON)` | `Resume (markdown)` |
| `{parsability_note}` | `note when format cannot be verified from JSON alone` | `note when format cannot be verified from markdown alone` |

- [ ] **Step 4: Update Resolve inputs workflow**

Step 1 should:
1. Read `data/config.yaml` for `output_language` and `integrations.resume_matcher.enabled` (default `false`).
2. Resolve JD (unchanged).
3. If matcher enabled: load JSON from user path/inline; pretty-print if minified; error/ask if missing.
4. If matcher disabled: load `profile.resume_path` unless user provides override path or paste; ask once if missing.
5. Record `resume_source`, `resume_format`, `resume_matcher_enabled` for artifact meta.

- [ ] **Step 5: Update Run the review step**

Substitute all six placeholders: `{output_language}`, `{job_description}`, `{resume_data}`, `{resume_format}`, `{resume_source_label}`, `{parsability_note}`.

- [ ] **Step 6: Update artifact JSON shape**

Add to `meta`:
```json
"resume_source": "",
"resume_format": "",
"resume_matcher_enabled": false
```

- [ ] **Step 7: Update When to use and manual commands**

Remove Resume-Matcher-only framing from "When to use". Add examples for standalone (`/resume-feedback` with shortlisted role, no resume path) and matcher mode.

- [ ] **Step 8: Update follow-up step**

Change "updated resume JSON" to "updated resume" (path or paste).

- [ ] **Step 9: Commit**

```bash
git add .cursor/skills/resume-feedback/SKILL.md
git commit -m "feat: mode-aware input resolution for resume-feedback"
```

---

### Task 4: Update README apply workflow

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update apply workflow diagram**

Replace single path with two paths (standalone default vs Resume-Matcher optional), e.g.:

```
# Standalone (default)
shortlist → company-research → resume-feedback → apply → interview-prep

# With Resume-Matcher (integrations.resume_matcher.enabled: true)
shortlist → company-research → tailor via Resume-Matcher → resume-feedback → apply → interview-prep
```

- [ ] **Step 2: Rewrite Resume feedback subsection**

Document:
- Default: reviews markdown from `profile.resume_path` (or override path) vs JD
- Matcher mode: tailored JSON path required
- Config flag location
- Remove implication that JSON/Resume-Matcher is always required

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document standalone and Resume-Matcher resume-feedback paths"
```

---

### Task 5: Update company-research reminder

**Files:**
- Modify: `.cursor/skills/company-research/SKILL.md`

- [ ] **Step 1: Make step 5 reminder mode-aware**

In "Present to user", replace fixed "tailor resume and run resume-feedback" with:

- Matcher off (default): remind to run `resume-feedback` on master or tailored markdown before applying.
- Matcher on: remind to tailor via Resume-Matcher, then run `resume-feedback` on the JSON output.

Read `integrations.resume_matcher.enabled` from config when presenting (default `false`).

- [ ] **Step 2: Commit**

```bash
git add .cursor/skills/company-research/SKILL.md
git commit -m "docs: mode-aware resume-feedback reminder in company-research"
```

---

### Task 6: Manual validation

**Files:** none (verification only)

- [ ] **Step 1: Standalone smoke check**

With `integrations.resume_matcher.enabled: false` (or absent) and a real shortlisted role:
- Run `/resume-feedback` naming the role only (no resume path).
- Confirm: uses `profile.resume_path`, artifact saved, `meta.resume_format` is `markdown`, `meta.resume_matcher_enabled` is `false`.

- [ ] **Step 2: Matcher mode check**

Set `enabled: true` in local `data/config.yaml`, provide tailored JSON path.
- Confirm: v1.1 behavior, `meta.resume_format` is `json`.

- [ ] **Step 3: Git cleanliness**

Run: `git status`
Expected: no changes under `data/` staged or tracked

---

## Plan self-review

| Spec requirement | Task |
|------------------|------|
| `integrations.resume_matcher.enabled`, default false | Task 1, 3 |
| Standalone defaults to `profile.resume_path` | Task 3 |
| Matcher mode requires JSON | Task 3 |
| Prompt placeholders | Task 2, 3 |
| Extended artifact meta | Task 3 |
| README both paths | Task 4 |
| company-research reminder | Task 5 |
| Manual validation | Task 6 |
