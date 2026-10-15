# Hermes Support Design

Date: 2026-10-15
Branch: feature/hermes-support
Status: Approved

## Goal

Replicate Iago's existing Cursor / Claude Code platform support for Hermes
(Nous Research's agent framework) as a first-class option, and add Hermes
cron-scheduled daily search — a capability neither Cursor nor Claude Code
provides natively.

## Architecture Overview

Three layers, mirroring the established two-platform pattern. The shared
source of truth (`skills/*/WORKFLOW.md`) does not change.

| Layer | Change |
|---|---|
| In-repo wrappers | New `.hermes/skills/<name>/SKILL.md` × 8 |
| install-skills.sh | Add `--platform hermes`; `both` installs cursor+claude+hermes |
| verify-workspace.sh | Add hermes to the platform check |

### In-repo wrappers (8 skills)

iago-setup, iago-daily, update-application, company-research, resume-feedback,
interview-prep, iago-pipeline-review, iago-upgrade-version (mirroring Cursor's
set, which includes iago-upgrade-version; Claude's set lacks it — left as-is,
tracked separately if wanted).

Each wrapper contains:

1. Frontmatter copied verbatim from the shared skill (name, description)
2. Title header: `# <Name> (Hermes)`
3. Mandatory pointer to `$REPO_ROOT/skills/<name>/WORKFLOW.md`
4. REPO_ROOT resolution table, Hermes-flavoured:
   - Workspace contains `.hermes/skills/<name>/SKILL.md` → workspace root
   - Skill loaded from this repo → parent of `.hermes/skills`
   - Global skill symlink → `readlink -f "$HOME/.hermes/skills/<name>"` → parent of `.hermes/skills` on resolved path
   - Nested under parent workspace → `bash "$REPO_ROOT/scripts/verify-workspace.sh"` fallback
   - Unknown → ask user for the Iago clone path
5. `## Hermes-specific` section:
   - Multi-choice questions: plain numbered options in chat
   - After `install-skills.sh --platform hermes`: no reload needed; new sessions pick skills up automatically
   - iago-daily only: document `hermes cron create` scheduling command
   - iago-upgrade-version only: refresh skill symlinks after version bump

### install-skills.sh

- `--platform hermes`: symlink `.hermes/skills/*` → `$HERMES_HOME/skills/*`
  (or `~/.hermes/skills/*` when HERMES_HOME unset; mkdir -p the target)
- `both` becomes: cursor + claude + hermes
- Same per-skill outcomes as other platforms (installed / updated / skipped-not-a-symlink)

### verify-workspace.sh

- Accept `--platform hermes|cursor|claude|both` (default both)
- Check `.hermes/skills/iago-setup/SKILL.md` for the hermes/both cases
- Exit contract unchanged: 0 workspace-matches-repo, 1 corrupt/partial checkout, 2 nested layout

## Hermes Cron: Scheduled Daily Search

Hermes ships a first-class scheduler (`hermes cron` + Scheduled jobs in the
desktop app) that neither Cursor nor Claude Code provides.

### Runner

Generalize `scripts/run-daily-search.sh` with `--agent cursor|hermes`
(default `cursor`, backward compatible):

- `--agent hermes` resolves the `hermes` binary (HERMES_CLI_PATH override, then PATH), mirroring the existing `resolve_cursor()`
- Agent invocation: `hermes chat -q "$PROMPT" --in "$REPO_ROOT"` replaces `cursor agent -p --trust --force --workspace "$REPO_ROOT"`
- Everything else unchanged: config check, IAGO_TZ (default Australia/Brisbane), timestamped logs under data/logs/, latest.log symlink, prompt text

### Scheduling

One command, run once by the user:

```bash
hermes cron create "0 9 * * *" \
  "bash <iago-repo>/scripts/run-daily-search.sh --agent hermes"
```

Visible/managed via desktop Scheduled jobs and `hermes cron list/edit/pause/run`.
Documented in the iago-daily Hermes-specific section and the README Hermes subsection.

### Non-goals (YAGNI)

- No separate hermes-cron-setup skill — the one-line command lives in the iago-daily Hermes section + README; earns a skill only if scheduling later needs a wizard

## Data Flow Through Skill Wrappers

```
skills/<name>/WORKFLOW.md        ← shared source (unchanged)
        │
        ▼ (frontmatter copied verbatim)
.hermes/skills/<name>/SKILL.md   ← thin per-platform wrapper
        │
        ├─ title header: "# <Name> (Hermes)"
        ├─ mandatory WORKFLOW.md pointer
        ├─ REPO_ROOT resolution table (.hermes/skills paths)
        └─ ## Hermes-specific (chat-style multi-choice; no reload; cron note)
```

Discovery: clone → `install-skills.sh --platform hermes` → symlinks in
`~/.hermes/skills/` → any new Hermes session has `/iago-daily` etc. globally,
with REPO_ROOT resolved via the symlink row. Note: Hermes sessions launched
from the repo dir auto-load AGENTS.md context but NOT repo-local skills —
the install step is genuinely required, same as Cursor/Claude.

## Error Handling

No new failure modes; follows existing conventions (`set -euo pipefail`, exit codes, hints on stderr):

- install-skills.sh: HERMES_HOME unset → fall back to ~/.hermes/skills with mkdir -p
- verify-workspace.sh: reuses 0/1/2 exit contract
- run-daily-search.sh: unknown --agent → usage() + exit 1; missing hermes binary → "Hermes CLI not found. Set HERMES_CLI_PATH." mirroring the Cursor error
- Wrapper REPO_ROOT tables end in "ask user for clone path" — unchanged

## Testing Strategy

No repo test harness exists (issue #19 tracks a test suite; out of scope).
Verification is script-level, and becomes the PR checklist:

1. Symlink install: `install-skills.sh --platform hermes` → `~/.hermes/skills/iago-setup` is a symlink to the repo; `hermes skills list` shows all 8 enabled; `hermes skills inspect iago-setup` renders
2. Idempotency: re-run → "updated", no duplicates
3. verify-workspace.sh: all three exit codes (repo root → 0; from ~/Documents → 2; temp copy with .hermes/ removed → 1)
4. Daily runner: missing hermes binary → error + non-zero exit; real hermes → timestamped log + latest.log symlink, same shape as Cursor runs
5. Wrapper sanity: every .hermes/skills/*/SKILL.md frontmatter parses; REPO_ROOT tables reference .hermes/skills/<own-name> paths

## README Changes

- "Hermes skills" subsection alongside "Cursor skills" and "Claude Code skills"
- "Schedule with Hermes cron" note under the daily search instructions

## Out of Scope

- No changes to skills/*/WORKFLOW.md shared source
- No changes to data/, examples/, or pipeline scripts beyond run-daily-search.sh
- Claude's missing iago-upgrade-version skill (pre-existing gap; separate issue if wanted)
- Claude Cowork support — tracked as issue #43, starts after this PR merges to copy the generalized --agent pattern
