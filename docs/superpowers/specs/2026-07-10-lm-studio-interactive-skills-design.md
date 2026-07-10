# LM Studio Interactive Skills: Design

Closes [GitHub issue #36](https://github.com/lachlanmag/iago/issues/36).

## Goal

Make Iago usable **interactively in LM Studio chat** as a first-class local option alongside **Cursor** and **Claude Code**, without duplicating skill business logic.

Add a thin `.lmstudio/skills/` wrapper layer over shared `skills/*/WORKFLOW.md`, following the same platform pattern as `.claude/skills/` ([#33](https://github.com/lachlanmag/iago/issues/33) / [PR #38](https://github.com/lachlanmag/iago/pull/38)). That pattern is the template for later local platforms (Ollama / Open WebUI, [#37](https://github.com/lachlanmag/iago/issues/37)).

## Problem

LM Studio users want Iago without Cursor cloud or Claude Code. There is no documented path to load Iago's seven skills inside LM Studio chat and run the interactive workflow. v1 proves setup and daily end-to-end; the full apply chain is documented and optional if the local model struggles.

Issue #36 previously assumed pointing the plugin at `.cursor/skills/`. After #33, that mixes Cursor-specific wrappers with a third platform. A dedicated `.lmstudio/` tree keeps platform notes isolated and gives a repeatable layout for future runtimes.

**Constraints:**

- No duplicated business logic (workflow stays in `skills/`)
- Skills must read/write `data/` and invoke bash scripts via the plugin’s tools
- Cursor-only APIs (`AskQuestion`, `/loop`, browser MCP) need documented LM Studio fallbacks
- Headless / scheduled runs are out of scope (tracked in [#40](https://github.com/lachlanmag/iago/issues/40))

## Decisions (from brainstorming)

| Topic | Decision |
|-------|----------|
| Skill entrypoints | Thin tracked `.lmstudio/skills/` wrappers (not `.cursor/skills/` or bare `skills/`) |
| Plugin | Pin [khtsly/skills](https://lmstudio.ai/khtsly/skills) only; dirty-data out of scope for v1 |
| Web fetch | `run_command` + curl default; optional khtsly web-visit when pages block curl |
| Install depth | Verify wrappers + print absolute Skills Directory path; do not edit LM Studio config files |
| Spec timing | Write spec now; validate during implementation against mid-bar smoke |
| Approach | Extend the #33 platform pattern (`install-skills.sh --platform lmstudio`) |
| README | Separate Getting Started paths for Cursor, Claude Code, and LM Studio (detail in linked docs) |

## Scope

### In scope (v1)

- Tracked `.lmstudio/skills/<name>/SKILL.md` for all seven shipped skills
- Extend `scripts/install-skills.sh` with `--platform lmstudio`
- `scripts/verify-lm-studio.sh` preflight for the interactive path
- `docs/lm-studio-setup.md` full setup guide
- README restructure: three platform sections under Getting Started, with short steps and links to deeper docs where needed
- `scripts/init-data.sh` next-steps mention LM Studio
- Update issue #36 body to match `.lmstudio/skills/` (post-implementation or with the PR)
- Mid-bar interactive smoke (see Acceptance)

### Out of scope (v1)

- Pi agent, headless daily, launchd ([#40](https://github.com/lachlanmag/iago/issues/40))
- Publishing Iago as an LM Studio Hub plugin
- Supporting dirty-data or other skills-plugin forks in docs
- Auto-writing LM Studio plugin/settings JSON
- Ollama / Open WebUI ([#37](https://github.com/lachlanmag/iago/issues/37))
- Changing WORKFLOW business logic (QA gate, scoring, tracker schema)
- Replacing Cursor as the primary documented headless path

## Architecture

```
LM Studio chat (local model)
        ↓
khtsly/skills plugin (lms-plugin-skills)
  - <available_skills> injection
  - /skill-name explicit activation
  - read_skill_file, read_file, write_file, patch_file, run_command
        ↓
.lmstudio/skills/*/SKILL.md     ← thin wrappers (tracked)
        ↓
skills/*/WORKFLOW.md (+ prompt.md)   ← canonical workflow
        ↓
data/ (gitignored) + scripts/
```

### Directory layout

```
iago/
  skills/                              # canonical workflow (unchanged)
    <name>/WORKFLOW.md
    <name>/prompt.md                   # where applicable

  .cursor/skills/<name>/SKILL.md       # Cursor wrappers (unchanged)
  .claude/skills/<name>/SKILL.md       # Claude wrappers (unchanged)
  .lmstudio/skills/<name>/SKILL.md     # NEW: LM Studio wrappers

  docs/
    lm-studio-setup.md                 # NEW: interactive LM Studio guide
    # Cursor / Claude detail may stay in README or move to docs/*-setup.md
    # if README sections grow too long; prefer short README + link

  scripts/
    install-skills.sh                  # add --platform lmstudio
    verify-lm-studio.sh                # NEW
    verify-workspace.sh                # recognize .lmstudio as a valid platform marker
    init-data.sh                       # next-steps copy
```

### Separation of concerns

| Layer | Location | Contains |
|-------|----------|----------|
| Canonical workflow | `skills/<name>/WORKFLOW.md` | Search rules, QA gate, dedup, tracker writes, orchestration |
| Shared prompts | `skills/<name>/prompt.md` | Research / prep / feedback templates |
| LM Studio wrapper | `.lmstudio/skills/<name>/SKILL.md` | Frontmatter, mandatory WORKFLOW read, REPO_ROOT, LM Studio tool/fetch notes |

**Rule:** No business logic in wrappers. If a change affects what the agent *does*, it belongs in `WORKFLOW.md` or `prompt.md`.

## Wrapper contract

Every `.lmstudio/skills/<name>/SKILL.md` must:

1. Keep YAML frontmatter (`name`, `description`) with the same trigger phrases as Cursor/Claude (slash aliases included).
2. Open with:

   > Read and follow `$REPO_ROOT/skills/<name>/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

3. Include **Resolve REPO_ROOT** scoped to LM Studio:

   | Method | When |
   |--------|------|
   | Workspace contains `.lmstudio/skills/<name>/SKILL.md` | `REPO_ROOT` = workspace root |
   | Skill loaded from this repo | `REPO_ROOT` = parent of `.lmstudio/skills` |
   | Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
   | Still unknown | Ask user for the Iago clone path |

4. List **LM Studio-specific** affordances only:

   - Ask clarifying questions in chat (no `AskQuestion`)
   - File/tracker I/O via plugin tools (`read_file`, `write_file`, `patch_file`)
   - Shell via `run_command`
   - Web fetch: `run_command` + curl; optional [web-visit](https://lmstudio.ai/khtsly) if curl fails
   - No `/loop` or headless runner; re-run the skill in chat
   - Headless/scheduled runs: see [#40](https://github.com/lachlanmag/iago/issues/40)

5. Stay under ~80 lines.

### Skills in scope

All seven shipped skills get LM Studio wrappers in one pass:

| Skill | Notes |
|-------|-------|
| `iago-setup` | Ask in chat, one section at a time |
| `iago-daily` | curl / optional web-visit; no browser MCP |
| `iago-pipeline-review` | Manual re-run instead of `/loop` |
| `update-application` | Chains remain in WORKFLOW |
| `company-research` | curl or web-visit for SPAs |
| `interview-prep` | Minimal platform notes |
| `resume-feedback` | Minimal platform notes |

Orchestration unchanged: wrappers do not redefine chains.

## Script changes

### `scripts/install-skills.sh`

Extend platform enum:

```bash
bash scripts/install-skills.sh --platform lmstudio
```

| Platform | Behavior |
|----------|----------|
| `cursor` / `claude` | Unchanged: symlink project skills → `~/.cursor/skills` or `~/.claude/skills` |
| `both` | Remains **cursor + claude only** (IDE global discovery). Do not fold LM Studio into `both`. |
| `lmstudio` | Verify `$REPO_ROOT/.lmstudio/skills/*/SKILL.md` exist for all seven skills. Print the absolute path `$REPO_ROOT/.lmstudio/skills` for the user to paste into khtsly **Skills Directory Path**. Print: open LM Studio chat with workspace = repo root; link to `docs/lm-studio-setup.md`. Do **not** edit LM Studio config files. |

Optional later (not required for v1): symlink into `~/.lmstudio/skills/` for users who prefer the plugin default path. Prefer documenting the custom Skills Directory setting so seven symlinks are unnecessary.

### `scripts/verify-lm-studio.sh`

Preflight for interactive path:

- `.lmstudio/skills/<name>/SKILL.md` present for all seven skills
- Print absolute skills directory path
- Hint: workspace = repo root; khtsly plugin required
- Soft-check `data/config.yaml` (warn if missing; point at `/iago-setup`)
- Do not require Pi or LM Studio local server HTTP checks for v1 interactive chat (inference is in-app)

Exit non-zero if wrappers are missing.

### `scripts/verify-workspace.sh`

Treat `.lmstudio/skills/iago-setup/SKILL.md` as an additional valid platform marker for repo integrity (alongside `.cursor` / `.claude`). Pass if any one platform tree is present. Do not break existing cursor/claude behavior.

### `scripts/init-data.sh`

Next-steps echo: mention LM Studio path and `docs/lm-studio-setup.md` alongside Cursor and Claude.

## Documentation

### README.md (required)

Restructure **Getting Started** so each platform has its own clear path. Short steps in README; link out when detail would clutter the main page.

Suggested shape:

```markdown
## Getting Started

### Prerequisites
- Network access for job board search
- One of: Cursor, Claude Code, or LM Studio (+ khtsly/skills)

### 1. Clone
...

### 2. Choose your platform

#### Cursor
- Open repo root in Cursor
- Run setup in chat: "Set up job search" / `/iago-setup`
- Skills: `.cursor/skills/` (auto-discovered at repo root)
- Parent workspace / global install: link or short note → existing install-skills guidance
- Headless daily: existing Cursor Agent CLI section (or link)

#### Claude Code
- Open repo root (or `install-skills.sh --platform claude` for parent workspaces)
- Same chat triggers as Cursor
- Skills: `.claude/skills/`
- Headless: deferred to #34

#### LM Studio
- Install [khtsly/skills](https://lmstudio.ai/khtsly/skills)
- `bash scripts/install-skills.sh --platform lmstudio` (prints Skills Directory path)
- Paste path into plugin; open chat with workspace = Iago repo root
- `/iago-setup` then `/iago-daily`
- Full detail: [docs/lm-studio-setup.md](docs/lm-studio-setup.md)
- Automation / headless: #40
```

Also update:

- Intro blurb: not “Cursor-native” only; say multi-platform (Cursor, Claude Code, LM Studio) while keeping Cursor as the default happy path if needed for brevity
- Repo layout diagram: add `.lmstudio/skills/`
- Prerequisites: list all three platforms

If Cursor or Claude sections become long, extract to `docs/cursor-setup.md` / `docs/claude-setup.md` and keep README as the index. **LM Studio must have `docs/lm-studio-setup.md` in v1** because plugin + path + model notes do not fit a short README block.

### `docs/lm-studio-setup.md`

Cover:

1. Install LM Studio + tool-capable model (recommend Qwen Coder-class)
2. Install khtsly/skills from Hub
3. Run `install-skills.sh --platform lmstudio` and set Skills Directory
4. Open chat with workspace = repo root
5. `verify-lm-studio.sh`
6. First `/iago-setup` and `/iago-daily`
7. Fetch fallbacks (curl, optional web-visit)
8. Troubleshooting (skills not found, weak tool use, wrong workspace)
9. Pointer to #40 for automation

### ROADMAP

Already marks #36 in progress on this branch. After ship, move LM Studio interactive into Shipped / Platforms summary (implementation plan detail).

## Error handling

| Gap | v1 behavior |
|-----|-------------|
| Plugin missing / wrong skills path | verify script + setup doc |
| Workspace ≠ repo root | Docs + wrappers ask for clone path |
| Curl blocked / SPA | Optional web-visit; else note in report |
| Weak tool-calling | Recommend models in setup doc; mid-bar may skip optional skills |
| Headless needed | Point to #40 |

## Testing and acceptance

### Structural

- [ ] Seven `.lmstudio/skills/<name>/SKILL.md` wrappers
- [ ] Each mandates `$REPO_ROOT/skills/<name>/WORKFLOW.md`
- [ ] No workflow duplication in wrappers (`grep` QA gate / search rules only under `skills/`)
- [ ] Wrapper line count ≤ ~80

### Scripts / docs

- [ ] `install-skills.sh --platform lmstudio` prints absolute `.lmstudio/skills` path
- [ ] `both` still installs only cursor + claude
- [ ] `verify-lm-studio.sh` fails if a wrapper is missing
- [ ] README has separate Cursor, Claude Code, and LM Studio Getting Started paths
- [ ] `docs/lm-studio-setup.md` covers clone → plugin → first `/iago-setup`

### Interactive smoke (mid bar)

**Required** (record model used in the implementation plan):

- [ ] `/iago-setup` creates `data/config.yaml`
- [ ] `/iago-daily` writes `data/daily-runs/YYYY-MM-DD.md` and updates the tracker

**Optional** (document if skipped due to local model limits):

- [ ] `/iago-pipeline-review`
- [ ] `/update-application` shortlist → company-research
- [ ] `/update-application` applied → interview-prep
- [ ] `/resume-feedback`

## Acceptance criteria

- [ ] All seven skills discoverable interactively in LM Studio via khtsly + `.lmstudio/skills/`
- [ ] Same canonical `skills/*/WORKFLOW.md` as Cursor/Claude (no duplicated workflow text)
- [ ] `install-skills.sh --platform lmstudio` + `verify-lm-studio.sh` documented
- [ ] README documents Cursor, Claude Code, and LM Studio as separate Getting Started paths
- [ ] Platform gaps documented with concrete fallbacks
- [ ] Mid-bar smoke completed (or gaps recorded)
- [ ] Design spec + implementation plan under `docs/superpowers/`
- [ ] Issue #36 updated to describe `.lmstudio/skills/` (not `.cursor/skills/` as the plugin target)

## Success criteria

1. An LM Studio user can go from clone → plugin config → `/iago-setup` → a useful `/iago-daily` without Cursor or Claude Code.
2. Cursor and Claude users see no regression; their wrappers and `both` installer behavior stay intact.
3. Adding Ollama later is “another thin wrapper tree + README section,” not a redesign.
4. #40 remains the single tracking issue for Pi / headless LM Studio automation.

## Follow-up (not v1)

| Item | Issue |
|------|-------|
| Pi + headless daily / launchd | [#40](https://github.com/lachlanmag/iago/issues/40) |
| Ollama / Open WebUI wrappers | [#37](https://github.com/lachlanmag/iago/issues/37) |
| Claude Code headless | [#34](https://github.com/lachlanmag/iago/issues/34) |

## References

- Plugin: [khtsly/skills](https://lmstudio.ai/khtsly/skills) · [GitHub](https://github.com/imezx/skills)
- Prior platform design: `docs/superpowers/specs/2026-07-09-claude-code-skills-design.md`
- Related: #35 (discovery), #36 (this work), #37, #40
