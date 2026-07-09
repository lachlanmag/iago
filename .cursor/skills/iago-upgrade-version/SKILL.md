---
name: iago-upgrade-version
description: >-
  Upgrade the local Iago clone to the latest version from GitHub: git pull,
  merge new config keys, and refresh skill symlinks when needed. Use when the
  user says upgrade iago version, upgrade version, get latest iago, check for
  iago updates, sync iago, refresh iago, pull latest iago, or runs
  /iago-upgrade-version. Not for application tracker changes (use
  update-application).
---

# Iago upgrade version

## When to use

- User wants the latest Iago skills, scripts, or config template keys
- User says "upgrade Iago version", "upgrade version", "get latest Iago", "check for updates", "sync Iago", "refresh Iago"
- User runs `/iago-upgrade-version`
- After a release or when chat references a skill or script the user may not have yet

**Not** for application tracker changes (use `update-application`).

**Orchestrator:** Run the upgrade script on the user's behalf. Explain results in plain language. Only ask when blocked (dirty git tree, missing dependency, ambiguous repo path).

## Safety (tell user upfront if they seem anxious)

- Personal job search data lives in gitignored `data/` and is not deleted by `git pull`
- `reconcile-config` only **adds** missing keys from the example template; it never overwrites existing `data/config.yaml` values
- User must reload Cursor after a successful version upgrade so new skills load

## Files

| File | Purpose |
|------|---------|
| `$REPO_ROOT/scripts/upgrade-iago-version.sh` | Pull + config merge + optional `install-skills` |
| `$REPO_ROOT/scripts/reconcile-config.sh` | Called by upgrade script |
| `$REPO_ROOT/scripts/verify-workspace.sh` | Detect nested workspace layout |
| `$REPO_ROOT/scripts/install-skills.sh` | Symlink skills to `~/.cursor/skills/` when needed |
| `$REPO_ROOT/data/config.yaml` | May gain new keys only (values preserved) |

## Resolve REPO_ROOT (always first)

Same rules as `iago-setup`:

| Method | When |
|--------|------|
| Workspace contains `.cursor/skills/iago-setup/SKILL.md` | `REPO_ROOT` = Cursor workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.cursor/skills` |
| Global skill symlink | `readlink` on `~/.cursor/skills/iago-upgrade-version` or `iago-setup` → parent of `.cursor/skills` |
| Nested under parent workspace | Find `scripts/verify-workspace.sh` in a subfolder; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

Pass the Cursor workspace root to the upgrade script when known:

```bash
CURSOR_WORKSPACE="<cursor-workspace-path>" bash "$REPO_ROOT/scripts/upgrade-iago-version.sh"
```

## Workflow

### 1. Preflight

1. Resolve `REPO_ROOT`.
2. Confirm `$REPO_ROOT/.cursor/skills/iago-setup/SKILL.md` exists. If missing, stop: checkout is partial; re-clone Iago.
3. If user only asked whether a newer version exists, run:

   ```bash
   bash "$REPO_ROOT/scripts/upgrade-iago-version.sh" --check
   ```

   Summarize `status=up_to_date` or `status=version_upgrade_available` and recent commits. Ask whether to proceed with a full upgrade.

### 2. Preview config keys (optional)

If user wants to see config changes before applying:

```bash
bash "$REPO_ROOT/scripts/upgrade-iago-version.sh" --dry-run
```

Note: `--dry-run` previews reconcile against the **current** checkout. Run a full upgrade after pull if new template keys only exist on GitHub.

### 3. Full version upgrade

Run (with `CURSOR_WORKSPACE` when workspace root ≠ `REPO_ROOT`):

```bash
CURSOR_WORKSPACE="<cursor-workspace-path>" bash "$REPO_ROOT/scripts/upgrade-iago-version.sh"
```

On success, tell the user to reload Cursor: **Developer: Reload Window** (Cmd+Shift+P on Mac, Ctrl+Shift+P on Windows/Linux).

### 4. Handle failures

| Error | Action |
|-------|--------|
| `ruamel.yaml not installed` | Run `pip3 install ruamel.yaml` once, then retry upgrade |
| Uncommitted tracked changes | Show `git status --short`. Explain these are repo files (not `data/`). Offer stash or commit; do not force pull |
| Ahead and behind origin | Stop; user must resolve git divergence manually |
| `pull` auth / network failure | Report error; suggest checking network and GitHub access |
| `install-skills` skip (path exists, not symlink) | Warn user; they may need to remove conflicting `~/.cursor/skills/<name>` or open Iago repo root |

### 5. Confirm to user

Summarize:

- Whether pull ran or repo was already current
- Config keys added (from reconcile output) or "no new config keys"
- Whether global skills were refreshed (`install_skills=nested_workspace` vs `not_needed`)
- New `head` commit short hash
- **Reload Cursor** before running other Iago skills

## Out of scope

- Solo-maintainer dev clone + daily-driver layout (use `sync-daily-driver.sh` from the dev clone; see README maintainer note)
- Re-running `iago-setup` or resetting `data/`
- Committing or pushing user changes to GitHub
- Installing Cursor or `cursor agent login`
