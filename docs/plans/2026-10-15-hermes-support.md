# Hermes Support Implementation Plan

> **For implementer:** Use TDD throughout. Write failing test first. Watch it fail. Then implement. This repo has no unit-test harness (issue #19), so verification is script-level; each task ends with a concrete command and expected output.

**Goal:** Add Hermes Agent as a first-class Iago platform (skill wrappers, installer, workspace verifier, generalized daily runner) and document scheduling, matching the existing Cursor/Claude v1 support pattern.

**Architecture:** Shared `skills/*/WORKFLOW.md` files remain untouched. Each Hermes surface is a thin platform wrapper under `.hermes/skills/*/SKILL.md`, discovered via symlinks into `$HERMES_HOME/skills/` (or `~/.hermes/skills/`). `scripts/install-skills.sh` gains `hermes` and extends `both`; `scripts/verify-workspace.sh` gains hermes layout checks. `scripts/run-daily-search.sh` gains `--agent cursor|hermes`. Cosmetics/docs update the README.

**Tech Stack:** Bash scripts, Markdown platform wrappers, Hermes CLI (hermes chat -q, hermes cron), shared YAML/config runtime.

---

### Task 1: Package and orientation checkpoint

**Files:** none (verification only)

**Step 1: Verify full workspace state**

Command: `git status --short && git branch --show-current && git log --oneline -2`

Expected:
- output shows only (possibly) ignored files
- `feature/hermes-support`
- commits `e88c3a1` then `055aef7`

**Step 2: Verify tooling versions**

Command: `hermes --version && bash scripts/install-skills.sh --help >/dev/null 2>&1; bash scripts/verify-workspace.sh --help >/dev/null 2>&1; echo "scripts ok"`

Expected:
- Hermes version line printed
- `scripts ok` printed

**Commit:** none

---

### Task 2: Scaffold `.hermes/skills/` directory layout

**Files:**

- Create (directories will be filled in Task 3): `.hermes/skills/`

**Step 1: Create source skill-directory structure**

Command: `mkdir -p .hermes/skills && git rm -rf --ignore-unmatch .hermes/skills/.gitkeep 2>/dev/null; git ls-files .hermes`

Expected: no tracked `.hermes` files yet

**Step 2: Capture baseline and expected count**

Command: `wc -l scripts/install-skills.sh && find .claude/skills -maxdepth 1 -type d -print | tail -n +2 | wc -l`

Expected:
- install-skills.sh line count positive
- 8 Claude Code skill directories (iago-setup, iago-daily, update-application, company-research, resume-feedback, interview-prep, iago-pipeline-review, iago-upgrade-version)

**Commit:** none

---

### Task 3: Add Hermes platform skill wrappers (8 files)

**Files:**

- Create: `.hermes/skills/iago-setup/SKILL.md`
- Create: `.hermes/skills/iago-daily/SKILL.md`
- Create: `.hermes/skills/update-application/SKILL.md`
- Create: `.hermes/skills/company-research/SKILL.md`
- Create: `.hermes/skills/resume-feedback/SKILL.md`
- Create: `.hermes/skills/interview-prep/SKILL.md`
- Create: `.hermes/skills/iago-pipeline-review/SKILL.md`
- Create: `.hermes/skills/iago-upgrade-version/SKILL.md`

Template for each (replace `<name>` and optional per-skill notes):

```markdown
---
name: <skill-name-from-shared-source>
description: >-
  <copy exact description frontmatter from the corresponding .claude wrapper>
---

# <Human Title> (Hermes)

**Mandatory:** Read and follow `$REPO_ROOT/skills/<name>/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|---|---|
| Workspace contains `.hermes/skills/<name>/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.hermes/skills` |
| Global skill symlink | `readlink -f $HOME/.hermes/skills/<name>` → parent of `.hermes/skills` on resolved path |
| Nested under parent workspace | `bash "$REPO_ROOT/scripts/verify-workspace.sh" --platform hermes`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- After running `bash "$REPO_ROOT/scripts/install-skills.sh" --platform hermes` (or `--platform both`), no reload command is needed; skills are discovered by new Hermes sessions automatically.
- iago-daily only: To schedule the daily search, run `hermes cron create "0 9 * * *" "bash \"$REPO_ROOT/scripts/run-daily-search.sh\" --agent hermes"`.
- iago-upgrade-version only: After a git pull/version upgrade, re-run `install-skills.sh --platform hermes` to refresh local skill symlinks.
```

**Step 1: Create all 8 wrappers**

Command: use exact copy method from the shared source texts, adjusted per template.

Expected: 8 new `.hermes/skills/*/SKILL.md` files exist.

**Step 2: Validate wrapper frontmatter**

Command:
```bash
for f in .hermes/skills/*/SKILL.md; do
  echo "checking $f"
  grep -q '^---$' "$f" || exit 1
  grep -q '^name:' "$f" || exit 1
  grep -q "^# .* (Hermes)$" "$f" || exit 1
done
echo "frontmatter ok"
```

Expected: `frontmatter ok`

**Step 3: Validate REPO_ROOT resolution rows are peer-correct**

Command:
```bash
grep -R "/.hermes/skills/" .hermes/skills/*/SKILL.md | sort -u
```

Expected: one occurrence each for every `.hermes/skills/<name>/SKILL.md`, with matching skill names.

**Commit:** `git add .hermes && git commit -m "feat(iago): add Hermes agent skill wrappers (v1)"`

---

### Task 4: Extend install-skills.sh for Hermes

**Files:**

- Modify: `scripts/install-skills.sh`

Changes required:

1. Update usage text to include `hermes`, e.g. `--platform cursor|claude|hermes|both`
2. Add an `install_hermes()` function:

```bash
install_hermes() {
  echo "=== Hermes Agent ==="
  local hermes_dest="${HERMES_HOME:-$HOME/.hermes}/skills"
  install_platform "$REPO_ROOT/.hermes/skills" "$hermes_dest"
  echo "New Hermes sessions will discover skills automatically; reload running redbinding by restarting hermes as needed."
}
```

3. `both` should install cursor + claude + hermes. Consider renaming internally to make that explicit (e.g. introduce `all`) while retaining `both` for backward compatibility.

**Step 1: Edit install script**

Command: modify as above with your editor/patch. Save.

Expected: `bash scripts/install-skills.sh --help` output mentions hermes and both cursor+claude+hermes

**Step 2: Dry-run hermes install**

Command: `bash scripts/install-skills.sh --platform hermes`

Expected:
- Platform function resolves source `.hermes/skills`
- Each wrapper prints `installed: ...`
- Summary `installed=8 updated=0 skipped=0`

**Step 3: Verify idempotency**

Command: `bash scripts/install-skills.sh --platform hermes`

Expected:
- All 8 lines show `updated: ...`
- Summary `installed=0 updated=8 skipped=0`
- No duplicate skill names in `~/.hermes/skills/`

**Step 4: Verify `both` semantics**

Command (from repo root): `bash scripts/install-skills.sh --platform both`

Expected:
- cursor: updates 8
- claude: updates 8
- hermes: updates 8

**Commit:** `git commit -am "feat(iago): add --platform hermes to install-skills.sh"`

---

### Task 5: Extend verify-workspace.sh for hermes

**Files:**

- Modify: `scripts/verify-workspace.sh`

Changes required:

1. Update usage text to include `hermes`
2. Add hermes verification var:

```bash
hermes_skill="$REPO_ROOT/.hermes/skills/iago-setup/SKILL.md"
```

3. Add hermes branch in the platform `case`:

```bash
hermes)
  [[ -f "$hermes_skill" ]] && skills_ok=true
  ;;
```

4. Update the install hint to mention hermes:

```bash
install_hint="bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform both # platform selection"
```

**Step 1: Edit verifier**

Command: modify as above.

Expected: `bash scripts/verify-workspace.sh --platform hermes` runs without usage error.

**Step 2: Exit 0 from repo root**

Command: `bash scripts/verify-workspace.sh --platform hermes "$PWD"; echo "exit=$?"`

Expected:
- `skills_at_repo_root=yes`
- `workspace_matches_repo=yes`
- `exit=0`

**Step 3: Exit 1 missing repo skills**

Command:
```bash
tmpdir="$(mktemp -d)"
cp -r scripts "$tmpdir/"
bash "$tmpdir/scripts/verify-workspace.sh" --platform hermes "$tmpdir"; rc=$?
echo "exit=$rc"
rm -rf "$tmpdir"
```

Expected: `exit=1` and `skills_at_repo_root=no` (or analogous error)

**Step 4: Exit 2 nested parent workspace**

Command: `bash scripts/verify-workspace.sh --platform hermes "$HOME"; echo "exit=$?"`

Expected:
- `workspace_matches_repo=no`
- `exit=2`

**Commit:** `git commit -am "feat(iago): add --platform hermes to verify-workspace.sh"`

---

### Task 6: Generalize daily search runner to support Hermes

**Files:**

- Modify: `scripts/run-daily-search.sh`
- (Optional) Modify `skills/iago-daily/WORKFLOW.md`: no changes; keep platform-neutral.

Changes required:

1. Parse `--agent cursor|hermes` (default `cursor`). Add usage.
2. Mirror `resolve_cursor()` with `resolve_hermes()`:

```bash
resolve_hermes() {
  if [[ -n "${HERMES_CLI_PATH:-}" && -x "${HERMES_CLI_PATH}" ]]; then
    echo "${HERMES_CLI_PATH}"
    return
  fi
  if command -v hermes >/dev/null 2>&1; then
    command -v hermes
    return
  fi
  for candidate in "/Users/$USER/.hermes/hermes-agent" "/opt/homebrew/bin/hermes"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
  echo "Hermes CLI not found. Install Hermes or set HERMES_CLI_PATH." >&2
  exit 1
}
```

3. Select agent binary:

```bash
case "$AGENT" in
  cursor) AGENT_BIN="$(resolve_cursor)" ;;
  hermes) AGENT_BIN="$(resolve_hermes)" ;;
  *) echo "invalid --agent: $AGENT (cursor or hermes)" >&2; usage >&2; exit 2 ;;
esac
```

4. Change invocation:

```bash
if [[ "$AGENT" == "cursor" ]]; then
  CMD=( "$AGENT_BIN" agent -p --trust --force --workspace "$REPO_ROOT" )
  [[ -n "${CURSOR_AGENT_MODEL:-}" ]] && CMD+=(--model "$CURSOR_AGENT_MODEL")
else
  CMD=( "$AGENT_BIN" --in "$REPO_ROOT" -q )
  [[ -n "${HERMES_MODEL:-}" ]] && CMD+=(--model "$HERMES_MODEL")
fi
```

Keep the rest of prompt/log/run-date logic unchanged.

**Step 1: Implement hermes support**

Command: edit and save script.

Expected: `bash scripts/run-daily-search.sh --agent hermes --help` returns 2 (unknown args) but does not crash on parser

**Step 2: Provide missing hermes binary to assert error path**

Command:
```bash
(
  PATH="/usr/bin:/bin" bash scripts/run-daily-search.sh --agent hermes
  rc=$?
  echo "exit=$rc"
  [[ $rc -ne 0 ]] || exit 1
)
```

Expected:
- `Hermes CLI not found. Install Hermes or set HERMES_CLI_PATH.`
- `exit != 0`

**Step 3: Real run retains same log shape**

Command:
```bash
bash scripts/run-daily-search.sh --agent hermes
ls -l data/logs/latest.log
head -n 4 data/logs/latest.log
tail -n 5 data/logs/latest.log
```

Expected:
- exit 0 (or the real agent's real exit code, surfaced by the runner)
- `latest.log` symlink points to `daily-*.log`
- Log has start and finish lines with timestamps, repo path, agent identity

**Step 4: Backward-compatible default cursor run**

Command:
```bash
bash scripts/run-daily-search.sh --help 2>&1 | head -5 || true
```

Expected:
- Default behavior/docs unchanged (cursor still implied when no `--agent`)
- Existing invocation docs continue to work unchanged

**Commit:** `git commit -am "feat(iago): add Hermes runner to run-daily-search.sh"`

---

### Task 7: README and platform documentation for Hermes

**Files:**

- Modify: `README.md`
- Modify: `skills/iago-daily/WORKFLOW.md` only if needed for Hermes notes; otherwise leave untouched

Changes required:

1. Add `### Hermes Agent (hermes support)` subsection under "Getting Started" alongside Cursor and Claude Code:
   - Prerequisite: Hermes installed and `hermes setup` completed
   - `bash scripts/install-skills.sh --platform hermes`
   - start a new `hermes` session and run `/iago`
   - Unlike Cursor: no reload window required
   - Hermes desktop: project + sidebar grouping hermes support note as appropriate

2. Add "Schedule with Hermes cron" to "Upgrading Iago" support section:
   - `/iago-upgrade-version` refreshes skill symlinks
   - cron daily job: `hermes cron create "0 9 * * *" 'bash "$REPO_ROOT/scripts/run-daily-search.sh" --agent hermes'`
   - pauses/edits via `hermes cron pause|resume|edit` and desktop Scheduled jobs

3. Add "Hermes support" references in core workflows:
   - `iago-daily` supports Hermes run command
   - no special config bootstrap needed for cron; config.yaml reused as expected

**Step 1: Edit README**

Command: patch as above.

Expected: `grep -n "Hermes" README.md` shows at least 6 references across setup/upgrading/workflows

**Step 2: Check Markdown links and references**

Command:
```bash
grep -n "install-skills.sh\|run-daily-search.sh\|verify-workspace.sh" README.md | head -20
```

Expected:
- hermes references include both installer and runner
- no outdated "both" claim missing hermes

**Commit:** `git commit -am "docs(iago): document Hermes skills and cron scheduling"`

---

### Task 8: Workspace discovery and developer docs

**Files:**

- Modify (if present): `docs/ROADMAP.md` or platform tracking notes
- Modify: `.claude/...` none (do not break Claude parity in this task)
- Verify: `skills/iago-setup/WORKFLOW.md` repo root behavior covers Hermes nested layout

No structural docs change required. Only verify patterns.

**Step 1: Confirm no unreadable platform references**

Command:
```bash
grep -R "Cursor CLI\|Claude Code" docs/ README.md scripts/ 2>/dev/null | grep -i cursor | head -20
```

Expected: any Cursor-specific wording is intentional; Hermes docs do not overstate Cursor assumptions.

**Step 2: Update daily driver doc note only if docs mention agent restrictions**

Command: `grep -R "cursor agent" docs/ README.md scripts/*.sh | head -20`

Expected:
- existing cursor runner references remain
- run-daily-search generalized to support hermes

**Commit:** `git commit --allow-empty -m "docs(iago): Hermes workspace discovery verified"`

---

### Task 9: End-to-end validation and cleanup

**Files:** changed previously; no new files

**Step 1: Full hermes skill install end-to-end**

Command:
```bash
bash scripts/install-skills.sh --platform hermes
hermes skills list | grep -E "iago|superpowers"
```

Expected:
- 8 Iago skills enabled (plus superpowers intact)
- install summary `installed=8 updated=0 skipped=0` (or updated after re-run)

**Step 2: All three verifiers**

Command:
```bash
set -e
bash scripts/verify-workspace.sh --platform hermes "$PWD"
bash scripts/verify-workspace.sh --platform cursor "$PWD" >/dev/null
bash scripts/verify-workspace.sh --platform claude "$PWD" >/dev/null
echo "all verifier platforms pass"
```

Expected: `all verifier platforms pass`

**Step 3: Hermes global skills path**

Command: `readlink -f "$HOME/.hermes/skills/iago-setup" 2>/dev/null || readlink -f "${HERMES_HOME:-$HOME/.hermes}/skills/iago-setup"`

Expected: resolves to `/Users/<user>/git-repos/iago-3/.hermes/skills/iago-setup`

**Step 4: iago-daily is reachable from Hermes**

Command:
```bash
hermes skills inspect iago-daily | head -6
```

Expected: renders skill header showing name and description.

**Step 5: git review**

Command: `git status --short && git log --oneline -6`

Expected:
- only intended changes (docs, wrappers, scripts, install)
- no accidental data/ or untracked generated files except maybe logs (which remain gitignored)
- commit list includes design + planned commits

**Commit:** `git commit --allow-empty -m "feat(iago): Hermes agent support v1 verified"`

---

### Task 10: Execution mode handoff (planning metadata)

Record in the plan completion section:

- Run `hermes skills install s`? none needed
- Subagent execution uses hermes `delegate_task` and reviewer/test commands
- Manual execution waits on user command input between tasks
- Completion is measured by Task 9 verification evidence, not by pushed PR

---

### Task 11: Optional manual post-install registration

For users who want background daily jobs (not automatic in iago-setup):

1. Add cron entry exactly once:

```bash
hermes cron create "0 9 * * *" 'bash "$REPO_ROOT/scripts/run-daily-search.sh" --agent hermes'
```

2. Confirm with `hermes cron list`
3. Pause/disable with `hermes cron pause <job-id>` and `hermes cron resume <job-id>`
4. If `--agent hermes` binary cannot be found, set `HERMES_CLI_PATH=/path/to/hermes` before launch.

This task is optional and does not need commit.

---

### Completion Checklist

- [ ] `.hermes/skills/` has 8 wrappers
- [ ] `install-skills.sh --platform hermes` works
- [ ] `install-skills.sh --platform both` installs all 3 platforms
- [ ] `verify-workspace.sh --platform hermes` works (0/1/2 behavior)
- [ ] `run-daily-search.sh --agent hermes` works and parses errors
- [ ] README has Hermes setup + cron docs
- [ ] Hermes skills are enabled and inspectable
- [ ] commit history remains coherent

**Handoff:** use subagent-driven execution with one implementer + spec reviewer + quality reviewer per task, or run manually one task at a time.
