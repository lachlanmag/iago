# Iago Setup Skill: Design

## Goal

Add a Cursor-native **`iago-setup`** skill that walks new users through onboarding in conversation, initializes gitignored `data/` files when needed, and writes a valid `data/config.yaml` without hand-editing YAML.

No personal data, tracker history, or resume content is committed to git.

Closes [GitHub issue #1](https://github.com/lachlanmag/iago/issues/1) (MVP scope).

## Scope

### In scope (v1 / MVP)

- **`iago-setup` skill**: detect state, init data, collect profile and search config, validate, write YAML, summarize next steps
- **Init flow**: invoke `scripts/init-data.sh` when `data/` files are missing (skip existing tracker files on re-run)
- **Three modes** when `data/config.yaml` already exists: fresh setup, update config only, or cancel
- **Profile**: `resume_path` (verify on disk), `location`, `willing_to_relocate`
- **Roles**: confirm or reorder `role_priority`
- **Location rules**: local hybrid/on-site/remote; outside-local remote-only
- **Preferences**: industry focus, work model, seniority, AI exposure
- **Industry awareness**: `actively_targeting`, `prefer_to_avoid` (flag-only lists)
- **Resume fit**: read resume at `profile.resume_path`; suggest `core_themes` and `proof_points`; user confirms
- **Search sources**: site names first (not URLs); enable/disable defaults; resolve URLs from location + roles; add custom boards by name or URL
- **Watch list**: `watch_companies` for ATS monitoring
- **Validation**: resume path exists; URL sanity checks; remind user to run `git status`
- **README update**: recommend `iago-setup` as the primary onboarding path for new users

### Out of scope (v1)

- Launchd plist `__REPO_ROOT__` substitution ([#21](https://github.com/lachlanmag/iago/issues/21))
- Regional config presets ([#9](https://github.com/lachlanmag/iago/issues/9))
- Default source catalog ([#23](https://github.com/lachlanmag/iago/issues/23))
- Config validation script ([#14](https://github.com/lachlanmag/iago/issues/14))
- Importing existing applications from spreadsheet
- Customizing `deduplication`, `listing_freshness`, or `qa_gate` (leave example defaults)
- Committing any `data/` content

### Relationship to existing workflow

```
iago-setup       → first-time onboarding; writes data/config.yaml
iago-daily       → daily search (requires configured data/)
iago-pipeline-review → triage discovered roles
update-application   → shortlist / apply / status changes
```

## Architecture

**Approach:** Single skill file only (no `prompt.md`). Matches `update-application` orchestrator pattern. Agent runs conversational wizard in chat; no new scripts for v1.

```
iago/
  .cursor/skills/iago-setup/
    SKILL.md
  scripts/
    init-data.sh              # invoked when data/ missing (unchanged)
  examples/
    config.example.yaml       # schema reference (unchanged)
  docs/superpowers/specs/
    2026-07-07-iago-setup-design.md
```

### Tracked vs local data

| Path | Git | Purpose |
|------|-----|---------|
| `.cursor/skills/iago-setup/` | tracked | Onboarding skill |
| `data/config.yaml` | **ignored** | User search criteria (primary write target) |
| `data/applications.yaml` | **ignored** | Tracker (init only; not customized in v1) |
| `data/seen-jobs.yaml` | **ignored** | Dedup index (init only) |
| `data/recruiters.yaml` | **ignored** | Recruiter tracker (init only) |

## Workflow behavior

### 1. Detect state

On invoke, check:

| Condition | Action |
|-----------|--------|
| `data/` or core YAML files missing | Run `bash scripts/init-data.sh` |
| `data/config.yaml` exists with real values | Offer: **fresh setup**, **update config**, or **cancel** |
| Placeholder values still present | Treat as incomplete; proceed with setup |

**Placeholder detection** (non-exhaustive): `Your City, State`, `/path/to/your/master-resume.md`, `Example SaaS Co`, example SEEK URL comments only.

| Mode | Behavior |
|------|----------|
| **Fresh setup** | Re-copy `config.example.yaml` → `data/config.yaml`; tracker files skip-if-exists via init script |
| **Update config** | Section-by-section edits; preserve tracker history |
| **Cancel** | Stop without writes |

### 2. Conversational flow (one section at a time)

Present a short recap before writing each section. Use `AskQuestion` for multi-choice (work model, role order, board toggles).

| Step | Collects | Writes to |
|------|----------|-----------|
| **Profile** | `resume_path`, `location`, `willing_to_relocate` | `profile` |
| **Roles** | Confirm/reorder `role_priority` | `role_priority` |
| **Location rules** | Local hybrid/on-site/remote; outside-local remote-only | `location_rules` |
| **Preferences** | Industry focus, work model, seniority, AI exposure | `preferences` |
| **Industry awareness** | `actively_targeting`, `prefer_to_avoid` | `industry_awareness` |
| **Resume fit** | Read resume; suggest `core_themes`, `proof_points`; user confirms | `resume_fit` |
| **Search sources** | See § Search sources | `search_sources`, `excluded_sources` |
| **Watch list** | Company names for ATS monitoring | `watch_companies` |

### 3. Search sources

**Prerequisite:** `profile.location` and `role_priority` already collected.

**Step A — Present default boards by name** (not URLs):

| Display name | Config `id` |
|--------------|-------------|
| SEEK | `seek` |
| LinkedIn | `linkedin` |
| Company boards (ATS watch list) | `company_boards` |
| We Love Product | `niche_boards` |
| Indeed | `aggregators` |
| Employment Hero Jobs | `recruiters` |

**Step B — Ask:** which defaults to enable? Any additional sites to add?

**Step C — URL resolution:**

- **Enabled defaults:** agent builds or discovers metro-specific saved-search URLs from `location` + top `role_priority` titles. Use web search when needed. Store in `search_sources.boards[].urls`.
- **User-added sites:** if URL provided, validate it resolves; if name only, search for the board's job listing page for their market and add a new board entry with `id`, `name`, `urls`.
- **Disabled defaults:** add board `id` to `excluded_sources`.

**Step D — Confirm** enabled board list (names only) before write.

Leave `search_sources.order` at example default unless user disables boards (order unchanged; excluded boards skipped by `iago-daily`).

### 4. Resume fit

1. After user provides `profile.resume_path`, read the file.
2. Extract 4–6 `core_themes` aligned with PM/PO/BA role search.
3. Suggest optional `proof_points` (concrete resume highlights).
4. Present suggestions; user confirms, edits, or skips `proof_points`.
5. Leave `flag_strong`, `flag_good`, `flag_stretch`, `levels`, `strong_signals`, `stretch_signals` at example defaults.

### 5. Validate before write

| Check | On failure |
|-------|------------|
| `profile.resume_path` exists on disk | Block save; ask for corrected path |
| At least one search source enabled | Block save; ask to enable a board |
| URLs resolve (HTTP fetch or browser) | Warn; allow save if user confirms |
| No secrets requested or stored | N/A (skill never asks for API keys) |

Before final write, remind user: all output stays in gitignored `data/`; run `git status` to confirm nothing under `data/` is staged.

### 6. Write YAML

- **Primary:** merge collected values into `data/config.yaml`.
- **Tracker files:** leave at init defaults unless user is migrating data (out of scope v1).
- **Preserve:** on update mode, do not remove keys outside edited sections (e.g. `deduplication`, `qa_gate`).

### 7. Confirm to user

Summarize:

- What was written (section checklist)
- Path to `data/config.yaml`
- Next step: **Run the daily job search** (`iago-daily`)
- Optional: `bash scripts/reconcile-config.sh` after future repo upgrades

## Trigger phrases

| Trigger | Action |
|---------|--------|
| `set up job search` | Start setup wizard |
| `configure job search` | Start or update setup |
| `job search onboarding` | Start setup wizard |
| `/iago-setup` | Start setup wizard |

## Data model

### Config fields written (minimum viable)

| Section | Fields |
|---------|--------|
| `profile` | `resume_path`, `location`, `willing_to_relocate` |
| `role_priority` | ordered list |
| `location_rules` | `local.*`, `outside_local.*` |
| `preferences` | `industry`, `industry_focus`, `work_model`, `ai_exposure`, `min_seniority` |
| `industry_awareness` | `actively_targeting`, `prefer_to_avoid` |
| `resume_fit` | `core_themes`, `proof_points` |
| `search_sources` | `boards[]` (enabled), `order` (default) |
| `excluded_sources` | disabled board ids |
| `watch_companies` | company name list |

All other `config.yaml` keys remain from `examples/config.example.yaml` defaults.

## Documentation updates (implementation)

| File | Change |
|------|--------|
| `README.md` | Getting Started: recommend `iago-setup` before hand-editing; list trigger phrases |
| `docs/ROADMAP.md` | Mark `iago-setup` shipped when complete |
| `scripts/init-data.sh` | Optional: mention `iago-setup` in next-steps echo |

## Testing and validation

- **Fresh clone:** no `data/config.yaml` → init runs → config written with valid resume path.
- **Update mode:** existing tracker rows untouched; config sections update correctly.
- **Fresh mode:** config reset; tracker files preserved.
- **Resume missing:** save blocked until valid path.
- **Custom board:** user names a board → agent finds URL → new entry in `search_sources.boards`.
- **Sanitization:** `git status` shows no staged files under `data/`.

## Success criteria

1. New user can complete onboarding via chat without hand-editing YAML.
2. Skill is discoverable via description and trigger phrases.
3. `profile.resume_path` validated before save.
4. README documents setup skill as recommended onboarding path.
5. Skill behavior matches this spec and `.cursor/skills/iago-setup/SKILL.md`.

## Future work (not v1)

| Item | Issue | Notes |
|------|-------|-------|
| Launchd plist substitution | [#21](https://github.com/lachlanmag/iago/issues/21) | Auto `__REPO_ROOT__` in plist template |
| Regional presets | [#9](https://github.com/lachlanmag/iago/issues/9) | AU/US/UK starter URLs |
| Source catalog | [#23](https://github.com/lachlanmag/iago/issues/23) | Repo-maintained defaults by region |
| Config validation script | [#14](https://github.com/lachlanmag/iago/issues/14) | Run after setup or before daily search |
| Application import | [#1](https://github.com/lachlanmag/iago/issues/1) phase 2 | Spreadsheet → `applications.yaml` |
