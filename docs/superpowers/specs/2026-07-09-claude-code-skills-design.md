# Shared Skill Source and Claude Code Support: Design

Closes [GitHub issue #33](https://github.com/lachlanmag/iago/issues/33).

## Goal

Make Iago usable on **Claude Code** as a first-class option alongside **Cursor**, without duplicating skill business logic.

Introduce a shared `skills/` directory as the canonical source for workflow content. Keep thin platform wrappers in `.cursor/skills/` and `.claude/skills/` for discovery, REPO_ROOT resolution, and platform-specific interaction notes only.

## Problem

Today all seven Iago skills live entirely in `.cursor/skills/`. Each `SKILL.md` mixes:

- Portable workflow logic (search rules, QA gate, tracker schema, orchestration)
- Cursor-specific discovery (`~/.cursor/skills/`, workspace heuristics)
- Cursor-specific APIs (`AskQuestion`, Automation, `/loop`)

Claude Code discovers skills from `.claude/skills/` (project) or `~/.claude/skills/` (global). Copying seven skills would create two sources of truth that drift. Three skills also ship `prompt.md` templates that must stay single-sourced.

## Scope

### In scope (v1)

- **`skills/` canonical directory**: one `WORKFLOW.md` per skill; shared `prompt.md` where applicable
- **Thin Cursor wrappers**: refactor existing `.cursor/skills/<name>/SKILL.md` to delegate to `skills/<name>/WORKFLOW.md`
- **Thin Claude wrappers**: new `.claude/skills/<name>/SKILL.md` with Claude discovery and REPO_ROOT rules
- **`install-skills.sh`**: support `--platform cursor` (default), `--platform claude`, `--platform both`
- **`verify-workspace.sh`**: detect skills via `.cursor/` or `.claude/` markers; platform-agnostic hints
- **`run-daily-search.sh`**: update embedded prompt to reference `skills/iago-daily/WORKFLOW.md` (runner remains Cursor-only)
- **`init-data.sh`**: update next-steps echo for dual-platform skill install
- **README**: document Claude Code getting started alongside Cursor
- **ROADMAP**: note dual-platform skill support

### Out of scope (v1)

Tracked as follow-up in [#34](https://github.com/lachlanmag/iago/issues/34):

- Headless daily search via Claude Code CLI
- Unified or parameterized headless runner refactor
- Full platform-neutral repositioning of README tagline and marketing copy
- Build-time skill generation from templates
- CI / self-hosted runner support for Claude Code

Do not spec or implement #34 as part of this work.

## Architecture

### Directory layout

```
iago/
  skills/                              # canonical workflow (tracked)
    iago-daily/WORKFLOW.md
    iago-setup/WORKFLOW.md
    iago-pipeline-review/WORKFLOW.md
    update-application/WORKFLOW.md
    company-research/WORKFLOW.md
    company-research/prompt.md
    interview-prep/WORKFLOW.md
    interview-prep/prompt.md
    resume-feedback/WORKFLOW.md
    resume-feedback/prompt.md

  .cursor/skills/<name>/SKILL.md       # Cursor wrapper only (tracked)
  .claude/skills/<name>/SKILL.md       # Claude wrapper only (tracked)

  scripts/
    install-skills.sh                  # extended for both platforms
    verify-workspace.sh                # extended for both platforms
    run-daily-search.sh                # prompt path update only
    init-data.sh                       # next-steps copy update
```

### Separation of concerns

| Layer | Location | Contains |
|-------|----------|----------|
| **Canonical workflow** | `skills/<name>/WORKFLOW.md` | Search rules, QA gate, dedup, tracker writes, orchestration chains, file tables, trigger phrase tables (platform-neutral wording) |
| **Shared prompts** | `skills/<name>/prompt.md` | Templated LLM output (company-research, interview-prep, resume-feedback) |
| **Cursor wrapper** | `.cursor/skills/<name>/SKILL.md` | YAML frontmatter, mandatory "read WORKFLOW.md" instruction, Cursor REPO_ROOT table, `AskQuestion` / Automation / `/loop` notes |
| **Claude wrapper** | `.claude/skills/<name>/SKILL.md` | YAML frontmatter, mandatory "read WORKFLOW.md" instruction, Claude REPO_ROOT table, in-chat question guidance |

**Rule:** No business logic in wrappers. If a change affects what the agent *does*, it belongs in `WORKFLOW.md` or `prompt.md`.

### Wrapper contract

Every platform `SKILL.md` must:

1. Keep YAML frontmatter (`name`, `description`) with the same trigger phrases as today (slash aliases included).
2. Open with an explicit mandatory instruction:

   > Read and follow `$REPO_ROOT/skills/<name>/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

3. Include a **Resolve REPO_ROOT** section scoped to that platform.
4. List platform-specific interaction affordances (Cursor: `AskQuestion`, `/loop`; Claude: ask in chat).
5. Stay under ~80 lines. If growing larger, content belongs in `WORKFLOW.md`.

### REPO_ROOT resolution

Generalize the pattern already used in `iago-daily` and `iago-setup`. Platform wrappers differ only in discovery paths.

| Method | Cursor | Claude Code |
|--------|--------|-------------|
| Workspace contains platform skill dir | `REPO_ROOT` = workspace root if `.cursor/skills/<name>/SKILL.md` exists | Same with `.claude/skills/<name>/` |
| Skill loaded from repo checkout | `REPO_ROOT` = parent of `.cursor/skills` | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink` on `~/.cursor/skills/<name>` → parent of `.cursor/skills` | `readlink` on `~/.claude/skills/<name>` → parent of `.claude/skills` |
| Nested under parent workspace | `scripts/verify-workspace.sh` → parent of `scripts/` | Same |
| Still unknown | Ask user for Iago clone path | Same |

When workspace root ≠ `REPO_ROOT`, all file paths and scripts use `$REPO_ROOT/...` prefix.

**WORKFLOW.md** references paths as `$REPO_ROOT/data/...` (not bare `data/...`) for skills that already use that convention. Skills that today say "repo root is the Cursor workspace" get updated in `WORKFLOW.md` to "repo root is `$REPO_ROOT`".

### Skills in scope

All seven shipped skills migrate in one pass (avoid partial migration):

| Skill | WORKFLOW.md | prompt.md | Notes |
|-------|-------------|-----------|-------|
| `iago-daily` | yes | no | Largest file; headless section stays in WORKFLOW.md (Cursor runner only) |
| `iago-setup` | yes | no | `AskQuestion` stays in Cursor wrapper; WORKFLOW.md says "ask user" generically |
| `iago-pipeline-review` | yes | no | |
| `update-application` | yes | no | Orchestrator chains stay in WORKFLOW.md |
| `company-research` | yes | yes (move from `.cursor/`) | WORKFLOW.md links to sibling `prompt.md` |
| `interview-prep` | yes | yes (move) | Same |
| `resume-feedback` | yes | yes (move) | Same |

### Orchestration (unchanged behavior)

Chained skills remain defined in canonical workflow files:

```
update-application  → company-research (on shortlisted)
                   → interview-prep (on applied)
iago-pipeline-review → company-research (on promote to shortlisted)
```

Wrappers do not redefine chains. Each chained skill's wrapper still points at its own `WORKFLOW.md`.

## Script changes

### `scripts/install-skills.sh`

Add argument parsing:

```bash
# Default: cursor (backward compatible)
bash scripts/install-skills.sh
bash scripts/install-skills.sh --platform cursor
bash scripts/install-skills.sh --platform claude
bash scripts/install-skills.sh --platform both
```

| Platform | Source | Destination |
|----------|--------|-------------|
| cursor | `$REPO_ROOT/.cursor/skills/*` | `$HOME/.cursor/skills/*` |
| claude | `$REPO_ROOT/.claude/skills/*` | `$HOME/.claude/skills/*` |

Behavior unchanged per skill: symlink if missing, `ln -sfn` if existing symlink, skip if real file exists. Print reload hint per platform (Cursor: Reload Window; Claude: restart session or equivalent).

### `scripts/verify-workspace.sh`

- Accept optional `--platform cursor|claude` (default: check both skill trees at repo root).
- Pass if **either** `.cursor/skills/iago-setup/SKILL.md` or `.claude/skills/iago-setup/SKILL.md` exists at `REPO_ROOT` (repo integrity).
- Exit codes unchanged: `0` workspace matches repo, `2` nested/external layout, `1` skills missing.
- Hints mention `install-skills.sh --platform both` for combined workspaces.

### `scripts/run-daily-search.sh`

Update embedded prompt path only:

```
Read and follow the iago-daily skill at skills/iago-daily/WORKFLOW.md in this workspace.
```

No Claude CLI support in v1. Runner prerequisites remain Cursor-only.

### `scripts/init-data.sh`

- Echo "Installing skills" instead of "Installing Cursor skills".
- Call `install-skills.sh --platform both` (or document that users pick platform; **recommend `both`** so monorepo users get global discovery on either tool).
- Next-steps mention both Cursor and Claude Code chat triggers.

## Documentation updates

### README.md

Add a **Claude Code** subsection under prerequisites / getting started:

- Open repo root (folder containing `skills/` and `.claude/skills/`)
- Run `bash scripts/install-skills.sh --platform claude` for parent workspaces
- Chat triggers mirror Cursor ("Set up job search", "Run the daily job search", etc.)
- Note headless daily search is Cursor-only for now; link to #34

Keep existing Cursor instructions. Do not fully rebrand from "Cursor-native" in v1 (deferred to #34).

### docs/ROADMAP.md

Add row or note under Skills: dual-platform skill layout shipped with #33.

## Migration plan

Execute in order on branch `feature/claude-code-skills`:

1. Create `skills/` directory structure.
2. For each skill, move body content from `.cursor/skills/<name>/SKILL.md` → `skills/<name>/WORKFLOW.md`:
   - Strip YAML frontmatter from WORKFLOW.md.
   - Replace "Cursor workspace" with `$REPO_ROOT`.
   - Move platform-specific lines (AskQuestion, Automation, `/loop`, REPO_ROOT table) into wrapper.
3. Move `prompt.md` files to `skills/<name>/prompt.md`; update WORKFLOW.md links.
4. Replace `.cursor/skills/<name>/SKILL.md` with thin wrapper.
5. Add `.claude/skills/<name>/SKILL.md` wrapper (mirror structure, Claude paths).
6. Update scripts (`install-skills.sh`, `verify-workspace.sh`, `run-daily-search.sh`, `init-data.sh`).
7. Update README and ROADMAP.
8. Manual smoke test on both platforms (see below).

**No backward-compat symlink** from old in-wrapper paths. Wrappers are the only entry points; WORKFLOW.md is referenced by absolute `$REPO_ROOT` path.

## Testing and validation

### Structural checks

- [ ] Every skill has `skills/<name>/WORKFLOW.md`
- [ ] Every skill has `.cursor/skills/<name>/SKILL.md` and `.claude/skills/<name>/SKILL.md`
- [ ] No `prompt.md` remains under `.cursor/skills/` (only under `skills/`)
- [ ] Wrapper line count ≤ ~80 per file
- [ ] `grep` for duplicated QA gate / search rules text: appears once in `skills/`, not in wrappers

### Script checks

- [ ] `bash scripts/install-skills.sh --platform both` creates symlinks in both home dirs
- [ ] `bash scripts/verify-workspace.sh` exits 0 when repo root is cwd
- [ ] `bash scripts/verify-workspace.sh /parent/workspace` exits 2 with install hint
- [ ] `run-daily-search.sh` prompt references `skills/iago-daily/WORKFLOW.md`

### Manual smoke tests (Cursor)

- [ ] Skills discover at repo root without global install
- [ ] `iago-setup` resolves REPO_ROOT in parent workspace after `install-skills.sh --platform cursor`
- [ ] `update-application` shortlist chains `company-research`; prompt.md loads from `skills/`

### Manual smoke tests (Claude Code)

- [ ] Skills discover at repo root
- [ ] `iago-daily` loads WORKFLOW.md and reads `$REPO_ROOT/data/config.yaml`
- [ ] Global install via `install-skills.sh --platform claude` works from parent workspace

## Acceptance criteria

Matches [#33](https://github.com/lachlanmag/iago/issues/33):

- [ ] One canonical `skills/<name>/WORKFLOW.md` per skill (plus `prompt.md` where applicable)
- [ ] Thin `.cursor/` and `.claude/` wrappers with no duplicated business logic
- [ ] `install-skills.sh` supports cursor, claude, and both
- [ ] `verify-workspace.sh` handles both platform layouts
- [ ] REPO_ROOT resolution documented in both wrapper types
- [ ] README documents Claude Code alongside Cursor
- [ ] `run-daily-search.sh` references shared workflow path
- [ ] Implementation plan at `docs/superpowers/plans/2026-07-09-claude-code-skills.md`

## Success criteria

1. A Claude Code user can run the full Iago workflow (setup → daily → pipeline review → apply chain) without Cursor.
2. A Cursor user sees no behavior regression after migration.
3. Future skill edits touch `WORKFLOW.md` once; wrappers change only for platform discovery or API differences.
4. #34 remains the single tracking issue for headless Claude and broader platform automation.

## Follow-up (not v1)

| Item | Issue |
|------|-------|
| Headless Claude Code daily runner | [#34](https://github.com/lachlanmag/iago/issues/34) |
| Unified headless runner refactor | [#34](https://github.com/lachlanmag/iago/issues/34) |
| Platform-neutral README repositioning | [#34](https://github.com/lachlanmag/iago/issues/34) |
| Build-time skill generation | [#34](https://github.com/lachlanmag/iago/issues/34) |
| CI / self-hosted Claude automation | [#34](https://github.com/lachlanmag/iago/issues/34), relates to [#13](https://github.com/lachlanmag/iago/issues/13) |
