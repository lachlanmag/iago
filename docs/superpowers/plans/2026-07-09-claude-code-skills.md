# Shared Skill Source and Claude Code Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce canonical `skills/*/WORKFLOW.md` content with thin `.cursor/` and `.claude/` wrappers so Iago runs on Claude Code without duplicating business logic.

**Architecture:** One `WORKFLOW.md` per skill (plus shared `prompt.md` where applicable). Platform `SKILL.md` files handle discovery, REPO_ROOT resolution, and platform UI affordances only. Scripts gain `--platform` flags for global install.

**Tech Stack:** Markdown skills, bash scripts, YAML frontmatter. No code generation.

**Spec:** [2026-07-09-claude-code-skills-design.md](../specs/2026-07-09-claude-code-skills-design.md)  
**Issue:** [#33](https://github.com/lachlanmag/iago/issues/33)  
**Branch:** `feature/claude-code-skills`

---

### Task 1: Scaffold `skills/` directory

**Files:**
- Create: `skills/` (empty tree; populated in Tasks 2–6)

- [ ] **Step 1: Create top-level directory**

```bash
mkdir -p skills
```

- [ ] **Step 2: Verify branch**

```bash
git branch --show-current
```

Expected: `feature/claude-code-skills`

- [ ] **Step 3: Commit scaffold**

```bash
git add skills/.gitkeep 2>/dev/null || touch skills/.gitkeep && git add skills/.gitkeep
git commit -m "chore: scaffold skills/ directory for shared workflow source"
```

If `.gitkeep` is unnecessary (directory filled in same PR), skip this commit and commit with Task 2.

---

### Task 2: Migrate `iago-daily`

**Files:**
- Create: `skills/iago-daily/WORKFLOW.md`
- Modify: `.cursor/skills/iago-daily/SKILL.md` (replace with thin wrapper)
- Create: `.claude/skills/iago-daily/SKILL.md`

- [ ] **Step 1: Create WORKFLOW.md from existing SKILL.md**

Copy `.cursor/skills/iago-daily/SKILL.md` body (everything after closing `---` of frontmatter) to `skills/iago-daily/WORKFLOW.md`.

Edits in WORKFLOW.md:
- Remove lines 19–20 (`Cursor Automation`, `/loop` triggers) from "When to use" (move to Cursor wrapper only).
- Remove the entire `## Resolve REPO_ROOT` section (lines 34–46 today); wrappers own this.
- Replace "While Cursor is open:" in headless section with "In Cursor chat (interactive):".
- Ensure all paths use `$REPO_ROOT/` prefix consistently.

- [ ] **Step 2: Replace Cursor wrapper**

Replace `.cursor/skills/iago-daily/SKILL.md` with:

```markdown
---
name: iago-daily
description: >-
  Run the daily PM/PO/BA job search, surface new listings, and update the
  application tracker. Use when the user says daily job search, job hunt, find
  new jobs, run the job search, run the job search for today, check for jobs
  today, search for new PM roles, what's new on the boards, update the tracker
  from today's search, or runs /iago or /iago-daily.
---

# Daily job search (Cursor)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-daily/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.cursor/skills/iago-daily/SKILL.md` | `REPO_ROOT` = Cursor workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.cursor/skills` |
| Global skill symlink | `readlink -f "$HOME/.cursor/skills/iago-daily"` → parent of `.cursor/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Cursor-specific

- Cursor Automation or `/loop` can trigger this skill (e.g. `/loop 1d Run the daily job search`).
- Headless: `bash "$REPO_ROOT/scripts/run-daily-search.sh"` (Cursor Agent CLI only).
```

- [ ] **Step 3: Create Claude wrapper**

Create `.claude/skills/iago-daily/SKILL.md`:

```markdown
---
name: iago-daily
description: >-
  Run the daily PM/PO/BA job search, surface new listings, and update the
  application tracker. Use when the user says daily job search, job hunt, find
  new jobs, run the job search, run the job search for today, check for jobs
  today, search for new PM roles, what's new on the boards, update the tracker
  from today's search, or runs /iago or /iago-daily.
---

# Daily job search (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-daily/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/iago-daily/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/iago-daily"` → parent of `.claude/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask clarifying questions in chat when the workflow requires user input.
- Headless scheduled runs are Cursor-only for now ([#34](https://github.com/lachlanmag/iago/issues/34)).
```

- [ ] **Step 4: Verify wrapper size**

```bash
wc -l .cursor/skills/iago-daily/SKILL.md .claude/skills/iago-daily/SKILL.md skills/iago-daily/WORKFLOW.md
```

Expected: each wrapper ≤ 80 lines; WORKFLOW.md contains search rules and QA gate.

- [ ] **Step 5: Commit**

```bash
git add skills/iago-daily/ .cursor/skills/iago-daily/SKILL.md .claude/skills/iago-daily/
git commit -m "refactor: extract iago-daily workflow to shared skills/"
```

---

### Task 3: Migrate `iago-setup`

**Files:**
- Create: `skills/iago-setup/WORKFLOW.md`
- Modify: `.cursor/skills/iago-setup/SKILL.md`
- Create: `.claude/skills/iago-setup/SKILL.md`

- [ ] **Step 1: Create WORKFLOW.md**

Copy body from `.cursor/skills/iago-setup/SKILL.md` to `skills/iago-setup/WORKFLOW.md`.

Edits:
- Remove `## Resolve REPO_ROOT` section (wrapper-only).
- In step 0 (verify workspace), replace `Use AskQuestion` with "Present choices and ask the user to pick one".
- Replace `AskQuestion` elsewhere with "ask the user" / "present choices".
- Remove "Orchestrator" line referencing `AskQuestion` from top; keep "Conversational wizard. One section at a time."
- Change `bash "$REPO_ROOT/scripts/install-skills.sh"` hints to `bash "$REPO_ROOT/scripts/install-skills.sh" --platform both` (or cursor/claude as appropriate in confirm step).
- Update exit 1 message to mention `.cursor/skills/` or `.claude/skills/` at repo root.

- [ ] **Step 2: Replace Cursor wrapper**

Keep frontmatter unchanged. Wrapper includes REPO_ROOT table (`.cursor/` paths), mandatory WORKFLOW.md read, and:

```markdown
## Cursor-specific

- Use `AskQuestion` for multi-choice (work model, role order, board toggles, setup mode, workspace layout).
- After `install-skills.sh`, tell user: Cmd+Shift+P → Developer: Reload Window.
```

- [ ] **Step 3: Create Claude wrapper**

Same frontmatter and REPO_ROOT table (`.claude/` paths). Claude-specific:

```markdown
## Claude Code-specific

- Ask multi-choice questions in chat (work model, role order, board toggles, setup mode, workspace layout).
- After `install-skills.sh --platform claude`, restart or reload the Claude Code session if skills do not appear.
```

- [ ] **Step 4: Commit**

```bash
git add skills/iago-setup/ .cursor/skills/iago-setup/ .claude/skills/iago-setup/
git commit -m "refactor: extract iago-setup workflow to shared skills/"
```

---

### Task 4: Migrate `iago-pipeline-review` and `update-application`

**Files:**
- Create: `skills/iago-pipeline-review/WORKFLOW.md`, `skills/update-application/WORKFLOW.md`
- Modify: `.cursor/skills/iago-pipeline-review/SKILL.md`, `.cursor/skills/update-application/SKILL.md`
- Create: `.claude/skills/iago-pipeline-review/SKILL.md`, `.claude/skills/update-application/SKILL.md`

- [ ] **Step 1: Create WORKFLOW.md for each skill**

For each file, copy SKILL.md body minus frontmatter.

Edits per WORKFLOW.md:
- Remove REPO_ROOT section if present.
- Replace "Repo root is the Cursor workspace" with "Repo root is `$REPO_ROOT`. Prefix paths when workspace root ≠ `REPO_ROOT`."
- Prefix bare `data/` paths with `$REPO_ROOT/data/` where not already prefixed.
- Keep orchestrator chain instructions in `update-application` WORKFLOW.md unchanged.

- [ ] **Step 2: Create Cursor and Claude wrappers**

Use the Task 2 wrapper pattern for each skill:
- Preserve existing YAML frontmatter verbatim.
- Mandatory WORKFLOW.md read line.
- Platform REPO_ROOT table (`.cursor/` or `.claude/` paths, skill name in paths).
- Cursor wrapper: no extra APIs needed for these two skills.
- Claude wrapper: "Ask clarifying questions in chat when ambiguous."

- [ ] **Step 3: Commit**

```bash
git add skills/iago-pipeline-review/ skills/update-application/ \
  .cursor/skills/iago-pipeline-review/ .cursor/skills/update-application/ \
  .claude/skills/iago-pipeline-review/ .claude/skills/update-application/
git commit -m "refactor: extract pipeline-review and update-application workflows"
```

---

### Task 5: Migrate prompt-based skills

**Files:**
- Create: `skills/company-research/WORKFLOW.md`, `skills/company-research/prompt.md`
- Create: `skills/interview-prep/WORKFLOW.md`, `skills/interview-prep/prompt.md`
- Create: `skills/resume-feedback/WORKFLOW.md`, `skills/resume-feedback/prompt.md`
- Modify: `.cursor/skills/{company-research,interview-prep,resume-feedback}/SKILL.md`
- Delete: `.cursor/skills/{company-research,interview-prep,resume-feedback}/prompt.md`
- Create: `.claude/skills/{company-research,interview-prep,resume-feedback}/SKILL.md`

- [ ] **Step 1: Move prompt.md files**

```bash
git mv .cursor/skills/company-research/prompt.md skills/company-research/prompt.md
git mv .cursor/skills/interview-prep/prompt.md skills/interview-prep/prompt.md
git mv .cursor/skills/resume-feedback/prompt.md skills/resume-feedback/prompt.md
```

- [ ] **Step 2: Create WORKFLOW.md for each skill**

Copy SKILL.md bodies. Edits:
- Change `[prompt.md](prompt.md)` links to `[prompt.md]($REPO_ROOT/skills/<name>/prompt.md)` or sibling `[prompt.md](prompt.md)` with a note that path is relative to `skills/<name>/` when read from WORKFLOW.md (prefer: "Open `$REPO_ROOT/skills/company-research/prompt.md`").
- Replace "Cursor workspace" with `$REPO_ROOT`.
- Remove REPO_ROOT sections from WORKFLOW if duplicated in current iago-daily pattern.

`resume-feedback`: keep `integrations.resume_matcher.enabled` logic entirely in WORKFLOW.md (platform-agnostic).

- [ ] **Step 3: Create wrappers**

`resume-feedback` Cursor frontmatter must keep `disable-model-invocation: true` if Claude Code supports it; if unsupported, omit on Claude wrapper only (document in commit message).

- [ ] **Step 4: Verify no prompt.md under .cursor/**

```bash
find .cursor/skills -name 'prompt.md'
```

Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add skills/company-research/ skills/interview-prep/ skills/resume-feedback/ \
  .cursor/skills/company-research/ .cursor/skills/interview-prep/ .cursor/skills/resume-feedback/ \
  .claude/skills/company-research/ .claude/skills/interview-prep/ .claude/skills/resume-feedback/
git commit -m "refactor: move prompt templates to skills/ and add platform wrappers"
```

---

### Task 6: Extend `install-skills.sh`

**Files:**
- Modify: `scripts/install-skills.sh`

- [ ] **Step 1: Add platform argument parsing**

Replace script with logic:

```bash
PLATFORM="${1:-cursor}"
if [[ "${1:-}" == "--platform" ]]; then
  PLATFORM="${2:-cursor}"
fi

case "$PLATFORM" in
  cursor|claude|both) ;;
  *)
    echo "usage: $0 [--platform cursor|claude|both]" >&2
    exit 1
    ;;
esac
```

Extract existing symlink loop into function `install_platform() {

  local src_subdir="$1"   # .cursor/skills or .claude/skills
  local dest_subdir="$2"  # ~/.cursor/skills or ~/.claude/skills
  ...
}`

Call:
- `cursor` → install `.cursor/skills` → `~/.cursor/skills`
- `claude` → install `.claude/skills` → `~/.claude/skills`
- `both` → both calls

- [ ] **Step 2: Update reload hints**

After install, print:
- Cursor: `Cmd+Shift+P → Developer: Reload Window`
- Claude: `Restart Claude Code session if skills do not appear`

- [ ] **Step 3: Test all three modes**

```bash
bash scripts/install-skills.sh --platform cursor
bash scripts/install-skills.sh --platform claude
bash scripts/install-skills.sh --platform both
bash scripts/install-skills.sh   # default cursor
```

Expected: symlinks created/updated under `~/.cursor/skills/` and/or `~/.claude/skills/` for all seven skill names.

- [ ] **Step 4: Commit**

```bash
git add scripts/install-skills.sh
git commit -m "feat: install-skills.sh supports cursor, claude, and both platforms"
```

---

### Task 7: Extend `verify-workspace.sh`

**Files:**
- Modify: `scripts/verify-workspace.sh`

- [ ] **Step 1: Add optional --platform flag**

Default: check repo has skills at either `.cursor/skills/iago-setup/SKILL.md` OR `.claude/skills/iago-setup/SKILL.md`.

Exit 1 only if **neither** exists.

- [ ] **Step 2: Update hints**

Replace install hint with:

```
bash "$REPO_ROOT/scripts/install-skills.sh" --platform both
```

Mention opening `$REPO_ROOT` in Cursor or Claude Code.

- [ ] **Step 3: Test exit codes**

```bash
cd /path/to/iago-clone
bash scripts/verify-workspace.sh
echo "exit=$?"

bash scripts/verify-workspace.sh /tmp/parent-workspace
echo "exit=$?"
```

Expected: `0` when cwd is repo root; `2` when workspace is parent and repo is nested.

- [ ] **Step 4: Commit**

```bash
git add scripts/verify-workspace.sh
git commit -m "feat: verify-workspace.sh supports dual-platform skill layout"
```

---

### Task 8: Update `run-daily-search.sh` and `init-data.sh`

**Files:**
- Modify: `scripts/run-daily-search.sh`
- Modify: `scripts/init-data.sh`

- [ ] **Step 1: Update daily search prompt path**

In `run-daily-search.sh`, change PROMPT opening line to:

```
Read and follow the iago-daily workflow at skills/iago-daily/WORKFLOW.md in this workspace.
```

- [ ] **Step 2: Update init-data.sh**

Change:
- `Installing Cursor skills` → `Installing skills`
- `bash "$REPO_ROOT/scripts/install-skills.sh"` → `bash "$REPO_ROOT/scripts/install-skills.sh" --platform both`
- Next-steps line 1: mention Cursor and Claude Code ("Set up job search" in either tool)
- Keep resume-feedback / Resume-Matcher line unchanged

- [ ] **Step 3: Commit**

```bash
git add scripts/run-daily-search.sh scripts/init-data.sh
git commit -m "chore: point headless daily run at shared workflow; dual-platform init"
```

---

### Task 9: Update README and ROADMAP

**Files:**
- Modify: `README.md`
- Modify: `docs/ROADMAP.md`

- [ ] **Step 1: Add Claude Code prerequisites**

Under Prerequisites, add:

```markdown
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (optional alternative to Cursor)
```

- [ ] **Step 2: Add dual-platform skills section**

After "### Cursor skills", add "### Claude Code skills" with:
- Skills ship in `.claude/skills/`; canonical workflow in `skills/`
- Open repo root as workspace
- Parent workspace: `bash scripts/install-skills.sh --platform claude` (or `both`)
- Same chat triggers as Cursor

Rename "### Cursor skills" intro to note shared `skills/` source briefly.

- [ ] **Step 3: Note headless limitation**

In headless daily search section, add one line: headless runs require Cursor Agent CLI; Claude Code headless is [#34](https://github.com/lachlanmag/iago/issues/34).

- [ ] **Step 4: Update repo layout in README**

Add `skills/` and `.claude/skills/` to directory tree diagram.

- [ ] **Step 5: Update ROADMAP**

Under Skills table or a new Platform row, add note: dual-platform skill layout (Cursor + Claude Code) shipped via #33.

- [ ] **Step 6: Commit**

```bash
git add README.md docs/ROADMAP.md
git commit -m "docs: document Claude Code skill support and shared skills/ layout"
```

---

### Task 10: Structural validation pass

**Files:**
- Verify: all paths from spec checklist

- [ ] **Step 1: Count skills**

```bash
ls skills/*/WORKFLOW.md | wc -l
ls .cursor/skills/*/SKILL.md | wc -l
ls .claude/skills/*/SKILL.md | wc -l
```

Expected: 7 for each.

- [ ] **Step 2: Check wrapper line counts**

```bash
wc -l .cursor/skills/*/SKILL.md .claude/skills/*/SKILL.md
```

Expected: each file ≤ 80 lines (approximate; iago-setup wrappers may be slightly higher if verify-workspace notes included; move excess to WORKFLOW if so).

- [ ] **Step 3: Check for duplicated QA gate text**

```bash
rg -l "QA gate" .cursor/skills .claude/skills
rg -l "QA gate" skills/
```

Expected: matches only under `skills/`, not wrappers.

- [ ] **Step 4: Check for stale prompt.md paths**

```bash
find .cursor/skills -name 'prompt.md'
rg '\.cursor/skills/.*/prompt\.md' .
```

Expected: no `prompt.md` under `.cursor/skills/`; no references to old prompt paths.

- [ ] **Step 5: Commit spec + plan if not yet committed**

```bash
git add docs/superpowers/specs/2026-07-09-claude-code-skills-design.md \
        docs/superpowers/plans/2026-07-09-claude-code-skills.md
git commit -m "docs: add Claude Code shared skills spec and implementation plan"
```

Skip if already committed.

---

### Task 11: Manual smoke tests (human)

**Not automatable in CI.** Run before opening PR for #33.

- [ ] **Cursor:** Open repo root; invoke `iago-daily` trigger; confirm WORKFLOW loads and reads config.
- [ ] **Cursor:** Parent workspace + `install-skills.sh --platform cursor`; run `iago-setup`; REPO_ROOT resolves.
- [ ] **Cursor:** Shortlist via `update-application`; `company-research` chains and reads `skills/company-research/prompt.md`.
- [ ] **Claude Code:** Open repo root; invoke daily search; confirm WORKFLOW loads.
- [ ] **Claude Code:** `install-skills.sh --platform claude` from parent workspace; skills discover.
- [ ] **Resume Matcher path:** With `integrations.resume_matcher.enabled: false`, `resume-feedback` uses `profile.resume_path` from WORKFLOW (no platform difference).

---

## Plan self-review

| Spec requirement | Task |
|------------------|------|
| `skills/*/WORKFLOW.md` | Tasks 2–5 |
| Thin `.cursor/` wrappers | Tasks 2–5 |
| Thin `.claude/` wrappers | Tasks 2–5 |
| `prompt.md` in `skills/` | Task 5 |
| `install-skills.sh --platform` | Task 6 |
| `verify-workspace.sh` dual layout | Task 7 |
| `run-daily-search.sh` path | Task 8 |
| `init-data.sh` | Task 8 |
| README + ROADMAP | Task 9 |
| Validation | Task 10–11 |

Follow-up [#34](https://github.com/lachlanmag/iago/issues/34) intentionally excluded.
