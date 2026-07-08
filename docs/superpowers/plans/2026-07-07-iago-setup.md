# Iago Setup Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `iago-setup` skill so new users complete onboarding in chat and get a valid `data/config.yaml` without hand-editing YAML.

**Architecture:** Single `SKILL.md` orchestrator (no `prompt.md`). Agent detects state, runs `init-data.sh` when needed, walks user through sections, validates resume path, resolves search board URLs, writes gitignored config.

**Tech Stack:** Cursor skills (markdown/YAML frontmatter), `scripts/init-data.sh`, `examples/config.example.yaml`.

**Spec:** [2026-07-07-iago-setup-design.md](../specs/2026-07-07-iago-setup-design.md)

---

### Task 1: Create `iago-setup` skill

**Files:**
- Create: `.cursor/skills/iago-setup/SKILL.md`

- [ ] **Step 1: Create skill directory and file**

Create `.cursor/skills/iago-setup/SKILL.md` with this content:

```markdown
---
name: iago-setup
description: >-
  Guided job search onboarding that initializes gitignored data/ files and
  writes config.yaml from conversation. Use when the user says set up job
  search, configure job search, job search onboarding, first time setup,
  initialize job search, help me configure iago, or runs /iago-setup.
---

# Iago setup

## When to use

- First-time setup after cloning the repo
- User wants to configure search criteria without hand-editing YAML
- User says "set up job search", "configure job search", "job search onboarding", "first time setup", "initialize job search", "help me configure iago"
- User runs `/iago-setup`
- User re-runs setup to update `data/config.yaml`

**Orchestrator:** Conversational wizard. One section at a time. Recap before each write. Use `AskQuestion` for multi-choice.

## Files

| File | Purpose |
|------|---------|
| `examples/config.example.yaml` | Schema reference and default values |
| `data/config.yaml` | Primary write target (gitignored) |
| `data/applications.yaml` | Tracker (init only in v1) |
| `data/seen-jobs.yaml` | Dedup index (init only) |
| `data/recruiters.yaml` | Recruiter tracker (init only) |
| `profile.resume_path` in config | Local resume for fit theme extraction |

Repo root is the Cursor workspace.

## Workflow

### 1. Detect state

Check whether core files exist: `data/config.yaml`, `data/applications.yaml`, `data/seen-jobs.yaml`.

If any are missing, run:

```bash
bash scripts/init-data.sh
```

If `data/config.yaml` exists with non-placeholder values, use `AskQuestion`:

| Mode | Behavior |
|------|----------|
| **Fresh setup** | Copy `examples/config.example.yaml` → `data/config.yaml` (tracker files unchanged) |
| **Update config** | Section-by-section edits only |
| **Cancel** | Stop without writes |

**Placeholder signals:** `Your City, State`, `/path/to/your/master-resume.md`, `Example SaaS Co`, empty `proof_points` with otherwise example-only config.

### 2. Profile

Collect and confirm:

- `profile.resume_path` (absolute path; **verify file exists** before continuing)
- `profile.location` (city, state/region, country as user prefers)
- `profile.willing_to_relocate` (boolean)

Suggest keeping the resume outside this repo.

### 3. Roles

Present default `role_priority` from example config. Ask user to confirm or reorder. Typical order: PM → Senior PM → PO → Senior PO → BA → Senior BA. Drop titles they do not want.

### 4. Location rules

Use `AskQuestion` where helpful:

| Field | Question |
|-------|----------|
| `location_rules.local.include_hybrid` | Accept hybrid roles in local metro? |
| `location_rules.local.include_on_site` | Accept on-site roles in local metro? |
| `location_rules.local.include_remote` | Accept remote roles in local metro? |
| `location_rules.outside_local.require_remote` | Outside local metro: remote only? (default yes) |

### 5. Preferences

Collect:

- `preferences.industry` (free text, e.g. "B2B SaaS preferred")
- `preferences.industry_focus` (optional single label from `industry_labels`, or null)
- `preferences.work_model` (e.g. hybrid preferred for local metro)
- `preferences.min_seniority` (e.g. mid, senior)
- `preferences.ai_exposure` (default `bonus_only`)

### 6. Industry awareness

Collect two optional lists (flag-only; never filter search):

- `industry_awareness.actively_targeting` (★ highlight in daily reports)
- `industry_awareness.prefer_to_avoid` (⚠ flag only)

Use labels from `industry_labels` in config when possible.

### 7. Resume fit

1. Read the file at `profile.resume_path`.
2. Suggest 4–6 `resume_fit.core_themes` tailored to PM/PO/BA search.
3. Suggest optional `resume_fit.proof_points` (concrete highlights from resume).
4. Present suggestions; user confirms or edits.
5. Leave `flag_strong`, `flag_good`, `flag_stretch`, `levels`, `strong_signals`, `stretch_signals` at example defaults.

### 8. Search sources

**Prerequisite:** `profile.location` and `role_priority` already set.

**Step A — Present default boards by name** (not URLs):

| Display name | Config `id` |
|--------------|-------------|
| SEEK | `seek` |
| LinkedIn | `linkedin` |
| Company boards (ATS watch list) | `company_boards` |
| We Love Product | `niche_boards` |
| Indeed | `aggregators` |
| Employment Hero Jobs | `recruiters` |

**Step B — Ask:** which defaults to enable? Any additional sites by name or URL?

**Step C — URL resolution:**

- For each **enabled** default: build or discover metro-specific saved-search URLs from `location` + top `role_priority` titles. Use web search when needed. Write to `search_sources.boards[].urls`.
- For **disabled** defaults: add board `id` to `excluded_sources`.
- For **user-added** sites: if URL given, verify it resolves; if name only, search for the board's job listing page for their market. Add new entry to `search_sources.boards` with unique `id`, `name`, `urls`.

**Step D — Confirm** final enabled board list (names only) before write.

Leave `search_sources.order`, `deduplication`, `listing_freshness`, and `qa_gate` at example defaults.

### 9. Watch list

Collect `watch_companies`: company names to monitor on ATS boards (Lever, Workable, Greenhouse, Ashby). Optional; empty list is fine.

### 10. Validate before write

| Check | On failure |
|-------|------------|
| `profile.resume_path` exists | Block save; ask for corrected path |
| At least one search source enabled | Block save |
| URLs resolve (fetch or browser) | Warn; allow save if user confirms |

Remind user: all output stays in gitignored `data/`. After setup, run `git status` to confirm nothing under `data/` is staged.

### 11. Write YAML

- Merge collected values into `data/config.yaml`.
- On **update** mode: preserve keys outside edited sections.
- Do not modify tracker files unless user is in fresh setup and config was reset.

### 12. Confirm to user

Summarize:

- Sections written
- Path to `data/config.yaml`
- Enabled search boards (names)
- **Next step:** Run the daily job search (`iago-daily` or "Run the daily job search")
- After repo upgrades: `bash scripts/reconcile-config.sh`

## Default board reference

When resolving URLs, start from `examples/config.example.yaml` → `search_sources.boards` structure. Adapt URLs to user's `profile.location` and market (AU, US, UK, etc.).

## Out of scope

- Launchd plist substitution
- Regional presets or source catalog
- Config validation script
- Importing applications from spreadsheet
- Customizing `deduplication`, `listing_freshness`, `qa_gate`
- Committing any `data/` content
```

- [ ] **Step 2: Verify skill file exists**

Run: `test -f .cursor/skills/iago-setup/SKILL.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add .cursor/skills/iago-setup/SKILL.md
git commit -m "feat: add iago-setup onboarding skill"
```

---

### Task 2: Update README Getting Started

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace Getting Started steps 1–3**

Replace the current Getting Started block (from `## Getting Started` through step 3 "In chat: **Run the daily job search**") with:

```markdown
## Getting Started

```bash
git clone git@github.com:lachlanmag/iago.git
cd iago
bash scripts/init-data.sh   # optional; iago-setup runs this if data/ is missing
```

**Recommended:** open the repo in Cursor and run guided setup:

> Set up job search

Trigger phrases: set up job search, configure job search, job search onboarding, `/iago-setup`.

The setup skill collects your location, role priorities, resume path, search boards, and watch list, then writes `data/config.yaml` for you.

**Manual alternative:** edit `data/config.yaml` directly:

- Set `profile.resume_path` to your local master resume (markdown, outside this repo)
- Set `profile.location`, role priorities, and search source URLs for your market
- Optional: `profile.output_language` for research, prep, and feedback artifacts

Then in chat: **Run the daily job search**
```

Note: preserve the fenced code block syntax correctly (nested fences may need adjustment when editing; use a single bash fence for clone/init, then prose below).

- [ ] **Step 2: Add iago-setup to Repository Layout**

In the `.cursor/skills/` tree under `## Repository Layout`, add after `iago-daily/`:

```
    iago-setup/                    # Onboarding; /iago-setup
```

- [ ] **Step 3: Add to "What Iago handles" list**

Under `### What Iago handles`, add as first bullet:

```markdown
- Guided first-time setup (`iago-setup`)
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: recommend iago-setup in README getting started"
```

---

### Task 3: Update ROADMAP

**Files:**
- Modify: `docs/ROADMAP.md`

- [ ] **Step 1: Mark iago-setup shipped in Skills table**

Change the `iago-setup` row from:

```markdown
| `iago-setup` | Planned | [#1](https://github.com/lachlanmag/iago/issues/1) | Conversational onboarding; writes gitignored `data/` YAML |
```

to:

```markdown
| `iago-setup` | **Shipped** | [#1](https://github.com/lachlanmag/iago/issues/1) | Conversational onboarding; writes gitignored `data/` YAML |
```

- [ ] **Step 2: Update Now (v1.1) setup item**

In the "Now (v1.1)" table, strike through or mark setup item done. Change row 1 to:

```markdown
| 1 | ~~**Setup skill**~~ | [#1](https://github.com/lachlanmag/iago/issues/1) | Shipped: `iago-setup` guided onboarding. Launchd plist ([#21](https://github.com/lachlanmag/iago/issues/21)) remains separate. |
```

- [ ] **Step 3: Commit**

```bash
git add docs/ROADMAP.md
git commit -m "docs: mark iago-setup shipped on roadmap"
```

---

### Task 4: Update init-data.sh next steps

**Files:**
- Modify: `scripts/init-data.sh`

- [ ] **Step 1: Add iago-setup to echo block**

Replace the `echo` next-steps block at the end of `scripts/init-data.sh` with:

```bash
echo
echo "Next steps:"
echo "  1. In Cursor chat: Set up job search  (or edit data/config.yaml manually)"
echo "     (after upgrades: bash scripts/reconcile-config.sh to add new example keys)"
echo "  2. Run: Run the daily job search"
echo "  3. After shortlisting: company-research runs automatically (or /company-research)"
echo "  4. Before applying: /resume-feedback, then set applied via update-application"
echo "     (default: markdown from profile.resume_path; matcher on: tailor via Resume-Matcher, provide JSON)"
```

- [ ] **Step 2: Commit**

```bash
git add scripts/init-data.sh
git commit -m "docs: mention iago-setup in init-data next steps"
```

---

### Task 5: Cross-reference from iago-daily

**Files:**
- Modify: `.cursor/skills/iago-daily/SKILL.md`

- [ ] **Step 1: Add prerequisite note**

After the `## Files (always read first)` table, add:

```markdown
**Prerequisite:** If `data/config.yaml` is missing or still has example placeholders, stop and tell the user to run `iago-setup` (or `bash scripts/init-data.sh` then configure manually).
```

- [ ] **Step 2: Commit**

```bash
git add .cursor/skills/iago-daily/SKILL.md
git commit -m "docs: point missing config users to iago-setup"
```

---

### Task 6: Manual validation

**Files:**
- None (verification only)

- [ ] **Step 1: Skill discoverability**

Confirm `.cursor/skills/iago-setup/SKILL.md` frontmatter `description` includes triggers: set up job search, configure job search, job search onboarding, `/iago-setup`.

- [ ] **Step 2: Init flow**

Run: `bash scripts/init-data.sh`
Expected: skip messages for existing files or creates missing ones.

- [ ] **Step 3: Git hygiene**

Run: `git status`
Expected: no staged or tracked files under `data/`

- [ ] **Step 4: End-to-end smoke test (optional, in Cursor chat)**

Run `/iago-setup` on a test clone or update mode against existing config. Confirm:

- Resume path validation blocks invalid paths
- Search boards presented by name
- `data/config.yaml` updated with user values
- Tracker files untouched in update mode

- [ ] **Step 5: Final commit if any fixups**

```bash
git status
# commit any fixups from smoke test
```

---

## Plan self-review (spec coverage)

| Spec requirement | Task |
|------------------|------|
| `iago-setup` skill with triggers | Task 1 |
| Init via `init-data.sh` | Task 1 § Workflow step 1 |
| Three modes (fresh / update / cancel) | Task 1 § Workflow step 1 |
| All config sections collected | Task 1 § Workflow steps 2–9 |
| Search sources: names first, URL resolution | Task 1 § Workflow step 8 |
| Resume fit from resume file | Task 1 § Workflow step 7 |
| Validation before write | Task 1 § Workflow step 10 |
| README recommends setup skill | Task 2 |
| ROADMAP marks shipped | Task 3 |
| Next step points to iago-daily | Task 1 § Workflow step 12 |
