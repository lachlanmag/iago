# External data folder — design

**Status:** approved in brainstorm, not implemented
**Branch:** `feature/external-data-dir`

## Goal

Keep Iago's personal data (`config.yaml`, `applications.yaml`, resumes, runs, etc.) in a folder **outside the repo**, chosen per machine, so it can be synced between computers by any tool (Nextcloud, Google Drive, Syncthing, rsync…) and can never be committed or pushed.

Iago does not sync anything itself. It only needs to be told, once per machine, which local folder holds the data.

## Non-goals

- Any sync logic or sync-tool integration.
- Native Windows support (symlinks need Developer Mode/admin). Windows users run Iago under WSL, where everything below works unchanged.
- Cleaning up existing clutter in `data/` (`__pycache__/`, `_*.py`, `*.bak.*`, `(conflicted copy …)` files). Listed as a manual step.

## Approach: per-machine symlink

`data` in the repo root becomes a symlink to the machine's chosen folder:

```
MacBook:   <repo>/data -> ~/Nextcloud/iago-data
Linux box: <repo>/data -> ~/sync/iago-data
```

Why a symlink rather than an env var or pointer file:

- About 20 skill `WORKFLOW.md` and `SKILL.md` files, the README and the scripts refer to `data/...` as plain text. Agents (Cursor, Claude Code, Hermes) read those paths literally and don't reliably expand `$IAGO_DATA_DIR`. A symlink keeps every existing path valid with zero rewrites.
- The link is local and gitignored, so each machine can point anywhere (different paths, macOS and Linux) and nothing machine-specific is committed or synced.
- Plain in-repo `data/` keeps working, so the feature is opt-in and backward compatible.

## Components

### 1. `scripts/link-data.sh <target>` (new)

| State | Behaviour |
|---|---|
| `data/` is a real dir with content, target missing/empty | Copy contents to a staging folder next to the target, verify (`diff -rq` + file count, no newly dangling relative symlinks), move it into place and verify again, rename `data/` aside, create the symlink, then delete the renamed copy (a failed delete only warns). |
| `data/` missing/empty, target has content (2nd machine) | Create the symlink. |
| `data/` missing/empty, target missing/empty | Create target, create the symlink (fresh setup). |
| Both have content | Refuse with a clear message. `--force` links anyway and leaves the local copy at `data.local-backup-<timestamp>/`. Never merges, never deletes. |
| `data` already a symlink | Print the current target. If a new target is given, re-point the link (does not move data). |
| Target resolves inside the repo | Refuse. |

- `~` in the target is expanded. The printed output uses `~`-relative paths.
- POSIX `sh`/`bash` only (macOS and Linux). Uses `ln -sfn`, plus `cp -Rp` and a count check (or `rsync -a` if available).

### 2. `.gitignore`

Replace:
```
data/*
!data/.gitkeep
```
with:
```
/data
/data.local-backup-*/
```
`data/*` does not match a symlink named `data`, so `/data` is required. Remove the tracked `data/.gitkeep`.

### 3. Guard in existing scripts

Add a shared check (`scripts/lib/data-dir.sh`, sourced) used by `run-daily-search.sh`, `init-data.sh`, `reconcile-config.sh`, `upgrade-iago-version.sh`, `sync-daily-driver.sh`:

- If `data` is a **broken** symlink (sync drive not mounted, folder renamed), exit non-zero with `data -> <target> does not exist. Mount/sync it or run scripts/link-data.sh <path>.` This avoids silently creating a fresh empty `data/` and losing track of state.
- `reconcile-config.py` gets the equivalent check in Python (`Path("data").is_symlink() and not Path("data").exists()`).

No other path logic changes. Everything resolves through the symlink.

### 4. `scripts/init-data.sh`

If `data` doesn't exist, prompt: `Where should Iago store your data? Enter a folder path (blank = keep in repo):`. If a path is given, call `link-data.sh`, then copy the templates as today.

Non-interactive flags, used by the `iago-setup` skill so the script doesn't prompt a second time:
- `--data-dir <path>`: link to the path, then init.
- `--keep-in-repo`: use a plain in-repo `data/` folder, then init.

When the target already has a `config.yaml` (another machine set it up), `init-data.sh` only links. It never overwrites existing files, which matches today's "copy only if missing" behaviour.

### 5. `scripts/verify-workspace.sh`

Report one of: `data: in-repo folder`, `data -> ~/Nextcloud/iago-data (ok)`, or `data -> … (BROKEN)`.

### 6. Paths inside the data folder

Synced files must not contain machine-specific absolute paths. Today `config.yaml` has:

```yaml
profile:
  resume_path: /Users/<you>/…/master-resume.md
```

New rule for `profile.resume_path` (and any future `*_path` keys):

- **Relative** → resolved against the data folder (for example `resumes/master-resume.md`). This is the recommended form.
- `~/…` → expanded per machine.
- **Absolute** → still accepted, with a warning in `verify-workspace.sh` that it may not exist on other machines.

Update `examples/config.example.yaml` to `resume_path: resumes/master-resume.md`, and update the skill text that reads `profile.resume_path` to say "relative to `data/`". `master_resume_source: api` already avoids this for the master resume.

### 7. Onboarding: choose the data folder (`iago-setup`)

Setup prompts for the data folder **before** any data files are created. This is a new step in `skills/iago-setup/WORKFLOW.md` (mirrored in the `.claude/`, `.cursor/` and `.hermes/` copies), between "0. Verify workspace and skills" and "1. Detect state", called **"0b. Choose data folder"**.

1. Run `link-data.sh --status`.
2. Branch on the mode:

| Mode | What setup does |
|---|---|
| `missing` (fresh clone) | **Always ask.** "Where should Iago keep your job search data? Pick a folder your sync tool (Nextcloud, Google Drive, Syncthing…) already syncs to use Iago on several computers, or keep it inside the repo." Choices: **Pick a folder** (recommended; opens the folder picker from the `iago-data-location` flow) / **Type a path** / **Keep in repo**. |
| `in-repo` with existing data | Show the current location and offer **Move to an external folder** or **Keep as is**. Not forced. |
| `linked` | Confirm: "Using `~/Nextcloud/iago-data`." Continue without asking. |
| `broken` | Stop setup until it's fixed: offer to re-point it, or ask the user to bring the sync folder online. Never initialise an empty folder in its place. |

3. Preview with `link-data.sh --dry-run <path>`, confirm, then run `init-data.sh --data-dir <path>` (or `--keep-in-repo`).
4. **Second machine:** if the chosen folder already contains a `config.yaml`, tell the user "Found existing Iago data (last updated …), linking to it." Step 1 then sees a populated config and offers **Update config** / **Cancel**, not **Fresh setup** by default.
5. When the user types a path, accept `~` and relative paths and expand them to absolute before linking. Show the resolved path back to the user.

Knock-on edits in the same workflow:
- Step 1 "Detect state": `data/` now resolves through the link. If any core files are missing, call `init-data.sh` with the choice made in 0b, never bare.
- Step 10 reminder: replace "all output stays in gitignored `data/`" with the actual location (for example, "your data is stored in `~/Nextcloud/iago-data` and is not part of the git repo").
- Step 12 confirmation: include the data folder location, and a note that any other computer needs setup (or `iago-data-location`) pointed at the same synced folder.
- Step 7 "Resume fit": when asking for the resume path, suggest copying the resume into `<data>/resumes/` and storing a data-relative `resume_path` (see section 6).

The setup flow and the `iago-data-location` skill share the same steps (status → pick → dry-run → confirm → link). Setup points to that skill's flow rather than copying it.

### 8. Docs

- README: in Quick start, after cloning, the first prompt is now "choose your data folder". Add a new section, "Storing data outside the repo / syncing between machines", covering choosing a folder in setup or later with `iago-data-location` or `link-data.sh`, syncing with any tool, never syncing the repo's `.git` through a file-sync tool, and WSL on Windows.
- Recommend keeping the repo itself out of synced folders (for example `~/git-repos/iago`). Syncing a git checkout tends to produce `(conflicted copy …)` files and corrupt repos.

### 9. `iago-data-location` skill (new)

Lets users view or change the data folder from chat in Cursor, Claude Code or Hermes, with no terminal needed. It follows the `iago-upgrade-version` pattern: a platform skill that wraps a script, with the agent running the script and explaining the result in plain language.

**Files:** `.cursor/skills/iago-data-location/SKILL.md`, `.claude/skills/iago-data-location/SKILL.md`, `.hermes/skills/iago-data-location/SKILL.md`. Same body, with platform frontmatter matching the sibling skills. `install-skills.sh` picks them up automatically.

**Triggers:** "where is my Iago data", "move my data", "change data folder", "set up sync", "data folder is missing or broken", "/iago-data-location".

**Workflow:**

1. Resolve `REPO_ROOT` (same table as `iago-setup` and `iago-upgrade-version`).
2. Run `link-data.sh --status`. Report it plainly: "Your data is in the repo" / "Your data is in `~/Nextcloud/iago-data`" / "The data folder `…` can't be found (sync drive not mounted?)".
3. If the user wants to change it, get a folder:
   - **macOS:** offer a native folder picker (`osascript -e 'POSIX path of (choose folder …)'`).
   - **Linux:** `zenity --file-selection --directory` if installed.
   - **Otherwise:** ask for the path in chat.
4. Run `link-data.sh --dry-run <target>` and show what will happen ("Move 412 files (18 MB) from the repo to `~/Nextcloud/iago-data`" / "Link to existing data, 412 files, last updated 2 days ago"). Ask for confirmation.
5. Run `link-data.sh <target>`, then `--status` again to confirm.
6. **Conflict** (both locations have data): show both sides (file count, newest `applications.yaml` modified time) and ask which to keep. Only pass `--force` after explicit confirmation, and say where the backup went.
7. **Broken link:** offer to re-point it to a different folder, or tell the user to bring the sync folder back online. Never create an empty folder at the old path without asking.

**Rules:** never delete data. Never edit `.gitignore`. Never `git add` or commit anything in `data/`. Tell the user that sync is their own tool's job and the skill only sets the location on this machine.

**Script support the skill needs** (add to `link-data.sh`):

- `--status`: prints `mode=in-repo|linked|broken|missing`, `target=…`, `files=N`, `bytes=N`, as stable `key=value` lines the agent can parse.
- `--dry-run <target>`: prints the planned action (`move`, `link`, `create`, `conflict`, `repoint`, `refuse`) and counts without changing anything.
- Exit codes: `0` ok, `2` conflict, `3` refused (target inside the repo), `4` broken link, `1` other error.

`iago-setup` calls this skill's flow for the "store data outside the repo?" onboarding step instead of duplicating it.

Also fix an existing gap found during design: `.claude/skills/` has no `iago-upgrade-version`. Out of scope here, but noted for a follow-up.

## Error handling summary

- Broken link → hard fail with a fix-it message (never auto-create).
- Conflicting data on both sides → refuse unless `--force`, which backs up and never deletes.
- Copy verification mismatch → abort before removing the source.
- Target inside the repo → refuse.

## Testing

`scripts/tests/test-link-data.sh` runs entirely in `mktemp -d` sandboxes (a fake repo plus a fake target) and covers:

1. First machine: in-repo data moved, symlink created, contents identical.
2. Second machine: empty local, populated target → link only.
3. Fresh setup: both empty.
4. Conflict: both populated → non-zero exit, nothing changed. With `--force`: backup dir exists, link created.
5. Re-point: an existing link changed to a new target, old target untouched.
6. Target inside the repo → refused.
7. Broken link → guard in `run-daily-search.sh` exits non-zero with a message.
8. `git status` in the sandbox repo shows no `data` entries (`.gitignore` works for a symlink).
9. `--status` output and exit codes for each mode (in-repo, linked, broken, missing).
10. `--dry-run` reports the correct action for every state and changes nothing (compare a before/after `find` listing).
11. `init-data.sh --data-dir <empty path>`: link created, templates copied into the target.
12. `init-data.sh --data-dir <path with existing config.yaml>`: link created, no existing file modified (compare checksums).
13. `init-data.sh --keep-in-repo`: a real `data/` directory, not a link.

Plus a unit test for `resume_path` resolution (relative, `~`, absolute).

Manual check: in each platform, ask "where is my Iago data?" and "move my Iago data to <tmp folder>" against a scratch clone. Then run "Set up job search" on a fresh scratch clone, twice: once picking an empty folder, and once picking the folder from the first run (second-machine path → offers Update config, not Fresh setup).

## Migrating an existing install

1. If the repo itself sits inside a synced folder, move it out (e.g. a fresh `git clone` into `~/git-repos/iago`), or exclude it from sync.
2. `bash scripts/link-data.sh ~/<sync-folder>/iago-data` (or ask chat: "Change my Iago data folder")
3. Change `profile.resume_path` to a data-relative path (or rely on `master_resume_source: api`).
4. Optionally delete clutter: `data/__pycache__`, `data/_*.py`, `*.bak.*`, `(conflicted copy …)`.
5. On each other machine: clone the repo, then `bash scripts/link-data.sh <that machine's folder>`.
