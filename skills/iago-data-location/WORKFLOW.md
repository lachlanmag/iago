# Iago data location

## When to use

- User asks where their Iago data is stored
- User wants to move data out of the repo, change the data folder, or use Iago on several computers ("set up sync", "use my Nextcloud/Google Drive folder")
- A script or skill reports that `data` points at a folder that does not exist
- User runs `/iago-data-location`
- Called from `iago-setup` step 0b (choose data folder)

**Not** for syncing files between computers. Iago only sets where data lives **on this machine**; the user's own sync tool (Nextcloud, Google Drive, Syncthing, …) keeps the folder in sync.

**Orchestrator:** Run the script on the user's behalf and explain results in plain language. Never ask the user to type terminal commands. Always preview and get confirmation before changing anything.

## Files

| File | Purpose |
|------|---------|
| `$REPO_ROOT/scripts/link-data.sh` | Status, dry-run, and link/move (only tool that changes the data location) |
| `$REPO_ROOT/data` | Real folder (in-repo) or per-machine symlink to the chosen folder; gitignored either way |

## Script contract

All output is `key=value` lines on stdout; hints and errors on stderr.

| Command | Output keys |
|---------|-------------|
| `bash "$REPO_ROOT/scripts/link-data.sh" --status` | `mode` (`missing`, `in-repo`, `linked`, `broken`), `repo`, `target`, `files`, `kb` |
| `bash "$REPO_ROOT/scripts/link-data.sh" --dry-run "<folder>"` | `action`, `mode`, `target`, `local_files`, `local_kb`, `target_files`, `target_kb` |
| `bash "$REPO_ROOT/scripts/link-data.sh" "<folder>"` | Same as dry-run, plus `result=ok` (and `backup=` when `--force` was used) |

| Exit | Meaning |
|------|---------|
| 0 | OK |
| 1 | Usage error, or copy verification failed (nothing removed) |
| 2 | Conflict: both `data/` and the folder have files; nothing changed |
| 3 | Refused: folder is inside the Iago repo |
| 4 | `--status` only: `data` points at a folder that does not exist |

| `action` | Meaning to tell the user |
|----------|--------------------------|
| `move` | "Move your N files (X MB) from the repo into `<folder>`, then link to it." |
| `link` | "`<folder>` already has Iago data (N files). Link to it; nothing is copied or overwritten." |
| `create` | "Start a new, empty data folder at `<folder>`." |
| `repoint` | "Switch from `<old>` to `<folder>`. Nothing is moved; the old folder is left as is." If `target_files=0`, warn: "the new folder is empty, so Iago will look like a fresh install." |
| `noop` | "Already using `<folder>`." |
| `conflict` | See Conflict below. |
| `refuse` | "That folder is inside the Iago repo; pick one outside it." |

## Workflow

### 1. Resolve REPO_ROOT

Per the platform wrapper. Run every command with `$REPO_ROOT`.

### 2. Report current location

Run `--status` and say, in one line:

| `mode` | Say |
|--------|-----|
| `missing` | "Iago has no data folder yet on this computer." |
| `in-repo` | "Your data is inside the Iago repo (`data/`, gitignored), N files." |
| `linked` | "Your data is in `<target>`, N files." |
| `broken` | "Iago is set to use `<target>`, but that folder can't be found (sync drive not mounted, or folder moved/renamed)." |

If the user only asked where the data is, stop here.

### 3. Choose a folder

Present choices:

| Choice | Action |
|--------|--------|
| **Pick a folder** (recommended) | macOS: `osascript -e 'POSIX path of (choose folder with prompt "Choose where Iago should keep your job search data")'`. Linux: `zenity --file-selection --directory --title="Iago data folder"` if `command -v zenity` succeeds. If the picker is unavailable or cancelled, fall back to **Type a path**. |
| **Type a path** | Accept `~/…`, relative, or absolute; the script expands it. |
| **Keep in repo** | Only offered when `mode` is `missing`: run `bash "$REPO_ROOT/scripts/init-data.sh" --keep-in-repo` (or return the choice to `iago-setup`). |
| **Cancel** | Stop without changes. |

Tip to offer: choose (or create) a folder **inside** what your sync tool already syncs, e.g. `~/Nextcloud/iago-data`. Never choose a folder inside the Iago repo.

**Broken link:** offer **Pick a different folder** (re-point) or **I'll reconnect the sync folder** (stop; ask the user to re-run once it is back). Never create an empty folder at the missing path without asking.

### 4. Preview and confirm

Run `--dry-run "<folder>"`, describe the `action` using the table above (convert `kb` to MB), and ask **Go ahead?** (Yes / Pick another folder / Cancel).

### 5. Apply and confirm

Run `link-data.sh "<folder>"`, then `--status`, and report the new location and file count. If called from `iago-setup`, return to setup.

### 6. Conflict (exit 2)

Both locations have data. Show both sides:

- This repo's `data/`: `local_files` files; modified time of `data/applications.yaml` (`ls -l` / `stat`)
- `<folder>`: `target_files` files; modified time of `<folder>/applications.yaml`

Ask which to keep:

| Choice | Action |
|--------|--------|
| **Use the folder's data** | Run `link-data.sh --force "<folder>"`. Tell the user the local copy was kept at `backup=` (inside the repo, gitignored) and can be deleted once they're happy. |
| **Keep this repo's data** | Do not use `--force`. Ask the user to pick an empty or new folder instead (or empty the other folder themselves first). |
| **Cancel** | Stop. |

Never merge the two automatically.

## Rules

- Never delete user data. The script only removes the in-repo `data/` after a verified copy.
- Never edit `.gitignore`, never `git add` anything under `data/`, never commit.
- Never pass `--force` without explicit confirmation in step 6.
- Paths shown to the user use `~/…` form, as the script prints them.
- After a change, remind the user: on each other computer, run this skill (or setup) and pick that computer's copy of the same synced folder; paths may differ per computer.
- macOS and Linux only. On Windows, tell the user to run Iago under WSL.
