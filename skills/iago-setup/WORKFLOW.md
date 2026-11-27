# Iago setup

## When to use

- First-time setup after cloning the repo
- User wants to configure search criteria without hand-editing YAML
- User says "set up job search", "configure job search", "job search onboarding", "first time setup", "initialize job search", "help me configure iago"
- User runs `/iago-setup`
- User re-runs setup to update `data/config.yaml`

**Orchestrator:** Conversational wizard. One section at a time. Recap before each write. Present choices and ask the user for multi-choice.

## Files

| File | Purpose |
|------|---------|
| `$REPO_ROOT/examples/config.example.yaml` | Schema reference and default values |
| `$REPO_ROOT/data/config.yaml` | Primary write target (gitignored) |
| `$REPO_ROOT/data/applications.yaml` | Tracker (init only in v1) |
| `$REPO_ROOT/data/seen-jobs.yaml` | Dedup index (init only) |
| `$REPO_ROOT/data/recruiters.yaml` | Recruiter tracker (init only) |
| `profile.resume_path` in config | Local resume for fit theme extraction (resolve per resume-feedback "Resolve `profile.resume_path`") |
| `$REPO_ROOT/scripts/link-data.sh` | Data folder status / link (step 0b; shared with `iago-data-location`) |

When Iago lives inside a larger workspace (notes, tasks, other rule sets), project skills may not auto-discover; use `install-skills.sh` as fallback.

## Workflow

### 0. Verify workspace and skills

1. Resolve `REPO_ROOT` (see above). Compare with the Cursor workspace root path (from session context).
2. Run:

   ```bash
   bash "$REPO_ROOT/scripts/verify-workspace.sh" "<workspace-path>"
   ```

3. **Exit 0 (workspace matches repo):** Skills should auto-discover. Continue to step 1.
4. **Exit 1 (skills missing at repo root):** Stop. Tell user the checkout is partial or corrupt (missing `.cursor/skills/iago-setup/SKILL.md` or `.claude/skills/iago-setup/SKILL.md`). Recovery: re-clone Iago or restore `.cursor/skills/` from the repo.
5. **Exit 2 (nested or monorepo layout):** Present choices and ask the user:

   | Choice | Action |
   |--------|--------|
   | **Open Iago folder** | Tell user: File → Open Folder → `REPO_ROOT`, reload window, re-run `/iago-setup` |
   | **Install skills globally** | Run `bash "$REPO_ROOT/scripts/install-skills.sh" --platform both`, tell user to reload Cursor, continue setup |
   | **Cancel** | Stop |

6. If user already chose global install earlier, or skills are not visible after reload, run `bash "$REPO_ROOT/scripts/install-skills.sh" --platform both` (idempotent) before continuing.

**Combined workspace note:** Parent folders (Obsidian vault + git repos) are fine for daily use once skills are symlinked to `~/.cursor/skills/`. Always prefix Iago file paths and scripts with `$REPO_ROOT` when workspace root ≠ `REPO_ROOT`.

### 0b. Choose data folder

Decide where this computer keeps Iago data **before** any data file is created. Follow `$REPO_ROOT/skills/iago-data-location/WORKFLOW.md` (steps 2–6) for the status → pick → preview → confirm → link flow; do not duplicate its logic here.

1. Run `bash "$REPO_ROOT/scripts/link-data.sh" --status`.
2. Branch on `mode`:

   | `mode` | Action |
   |--------|--------|
   | `missing` (fresh clone) | **Always ask:** "Where should Iago keep your job search data? To use Iago on more than one computer, pick a folder your sync tool (Nextcloud, Google Drive, Syncthing, …) already syncs. Or keep it inside the Iago repo." Choices: **Pick a folder** (recommended) / **Type a path** / **Keep in repo**. Remember the choice for step 1: `--data-dir "<target>"` using the resolved `target=` from the dry-run (expanded absolute or `~` form), or `--keep-in-repo`. For a folder, preview with `--dry-run` and confirm, but let step 1's `init-data.sh --data-dir` do the linking. |
   | `in-repo` with no files (`files=0`) | Treat as `missing`: ask the same question and remember the choice for step 1. |
   | `in-repo` with files | Say where the data is and offer **Move to a folder outside the repo** (run the iago-data-location flow now) or **Keep as is**. Never force a move. |
   | `linked` | Say "Using `<target>`." and continue without asking. |
   | `broken` | Stop setup. Offer **Pick a different folder** or **I'll reconnect the sync folder**. Never initialize an empty folder at the missing path. |
   | `unlinked` | Stop setup. Tell the user which folder Iago expects (`configured=`) and offer **Re-link to it**, **Pick another folder**, or, when `data/` is a real folder with files, **Keep the in-repo data** (`link-data.sh --unlink`; iago-data-location flow). Never run `init-data.sh` until `--status` reports `linked` or `in-repo`. |
   | `other` | Stop setup. A file named `data` is in the way; ask the user to move it. |

3. **Second computer:** if the chosen folder already contains `config.yaml`, say "Found existing Iago data (last updated <mtime of applications.yaml>). Linking to it; nothing will be overwritten." In step 1, default to **Update config**.
4. Typed paths may use `~` or be relative; show the resolved path from the dry-run `target=` line back to the user before confirming.

### 1. Detect state

Check whether core files exist: `$REPO_ROOT/data/config.yaml`, `$REPO_ROOT/data/applications.yaml`, `$REPO_ROOT/data/seen-jobs.yaml`.

If any are missing, run `init-data.sh` with the choice from step 0b (never bare, so it does not prompt a second time): pass `--keep-in-repo` if `link-data.sh --status` now says `in-repo` (or `missing` and the user chose **Keep in repo**), otherwise `--data-dir "<target from --status or the confirmed dry-run>"`:

```bash
bash "$REPO_ROOT/scripts/init-data.sh" --data-dir "<chosen folder>"   # or: --keep-in-repo
```

If 0b linked to a folder that already has a filled-in `config.yaml` (another machine), default to **Update config**, not **Fresh setup**.

If `data/config.yaml` exists with non-placeholder values, present choices and ask the user:

| Mode | Behavior |
|------|----------|
| **Fresh setup** | Copy `examples/config.example.yaml` → `data/config.yaml` (tracker files unchanged) |
| **Update config** | Section-by-section edits only |
| **Cancel** | Stop without writes |

**Placeholder signals:** `Your City, State`, `resumes/YOUR-RESUME.md` or `/path/to/your/master-resume.md` (older example), `Example SaaS Co`, empty `proof_points` with otherwise example-only config.

### 2. Profile

Collect and confirm:

- `profile.resume_path` (**verify file exists** before continuing, resolving per resume-feedback "Resolve `profile.resume_path`")
- `profile.location` (city, state/region, country as user prefers)
- `profile.willing_to_relocate` (boolean)

Suggest copying the resume into the data folder (`data/resumes/`) and saving a relative path such as `resumes/master-resume.md`: it stays out of git and syncs with the rest of the data. Absolute paths may not exist on the user's other machines; `~/` paths work if the file is at the same place under each machine's home folder.

### 3. Roles

Present default `role_priority` from example config (PM-focused example). Ask user to confirm, reorder, or replace with their target titles.

### 4. Location rules

Present choices and ask the user where helpful:

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

1. Read the file at `profile.resume_path` (resolve per resume-feedback "Resolve `profile.resume_path`").
2. Suggest 4–6 `resume_fit.core_themes` tailored to the user's target roles.
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
| `profile.resume_path` exists (resolved per resume-feedback "Resolve `profile.resume_path`") | Block save; ask for corrected path |
| At least one search source enabled | Block save |
| URLs resolve (fetch or browser) | Warn; allow save if user confirms |

Remind user where their data lives, using `link-data.sh --status`: e.g. "Your data is stored in `~/Nextcloud/iago-data`, outside the git repo" (or "in the repo's gitignored `data/` folder"). After setup, run `git status` to confirm nothing under `data/` is staged.

### 11. Write YAML

- Merge collected values into `$REPO_ROOT/data/config.yaml`.
- On **update** mode: preserve keys outside edited sections.
- Do not modify tracker files unless user is in fresh setup and config was reset.

### 12. Confirm to user

Summarize:

- Sections written
- Path to `$REPO_ROOT/data/config.yaml`
- Data folder location (from `link-data.sh --status`). If external: "On another computer, clone Iago and run setup (or ask *change my Iago data folder*) and pick the same synced folder."
- Enabled search boards (names)
- Skills status (auto-discovered at repo root, or installed to `~/.cursor/skills/`)
- **Next step:** Run the daily job search (`iago-daily` or "Run the daily job search")
- After version upgrades: run `iago-upgrade-version` ("Upgrade Iago version") or `bash "$REPO_ROOT/scripts/upgrade-iago-version.sh"`

## Default board reference

When resolving URLs, start from `examples/config.example.yaml` → `search_sources.boards` structure. Adapt URLs to user's `profile.location` and market (AU, US, UK, etc.).

## Out of scope

- Regional presets or source catalog
- Config validation script
- Importing applications from spreadsheet
- Customizing `deduplication`, `listing_freshness`, `qa_gate`
- Committing any `data/` content
