# External Data Folder Implementation Plan

> **For implementer:** Use TDD throughout. Write the failing test first, watch it fail, then implement. This repo has no unit-test harness (issue #19), so tests are a sandboxed bash script, `scripts/tests/test-link-data.sh`, that never touches the real `data/` or `$HOME`. Each task adds one section to it.

**Goal:** Let each machine point Iago's `data/` at a folder outside the repo (synced by any tool), set via setup, a chat skill, or one script, so personal data can never reach git.

**Architecture:** `data` becomes a per-machine, gitignored symlink created by `scripts/link-data.sh`. Every existing `data/...` path in scripts and skills keeps working unchanged. A small sourced guard (`scripts/lib/data-dir.sh`) makes scripts fail fast on a broken link. A new `iago-data-location` skill, plus a new step in `iago-setup`, drive the script from chat using its `--status` and `--dry-run` key=value output.

**Tech Stack:** Bash (macOS + Linux, BSD/GNU-portable), Python 3 (existing `reconcile-config.py`), Markdown skill workflows (Cursor / Claude Code / Hermes wrappers).

**Design:** `docs/plans/2026-11-25-external-data-dir-design.md`

**Prototype status:** every script and test in this plan was prototyped in a scratch copy of the repo. 47/47 tests pass on macOS (BSD `sed`, `du`, `cp`).

**Deviations from the design (decided while planning):**
- The `iago-data-location` skill follows the repo's majority pattern: shared `skills/iago-data-location/WORKFLOW.md` plus thin platform `SKILL.md` wrappers, not three full copies.
- The broken-link guard is wired into `run-daily-search.sh`, `init-data.sh` and `reconcile-config.sh`/`.py` only. `upgrade-iago-version.sh` reaches data only through `reconcile-config.sh`, and `sync-daily-driver.sh` never reads `data/` (YAGNI).
- Sizes are reported as `kb=` (portable `du -sk`), not bytes.
- `resume_path` portability is checked by `verify-workspace.sh` (tested). Resolution of relative paths is a documented rule in the skill workflows, because agents, not code, read that path.

---

### Task 0: Orientation checkpoint

**Files:** none

**Step 1:** `git status --short && git branch --show-current && git log --oneline -2`

Expected: branch `feature/external-data-dir`. The latest commit is `docs: design for external per-machine data folder`, and the only untracked entries are the pre-existing `.hermes/skills/iago-daily/iago-cold-outreach/` and `iago-tracker-operations/`. Do not stage those.

**Commit:** none

---

### Task 1: `link-data.sh` with status, dry-run, move/link/create/repoint/conflict/refuse

**Files:**
- Create: `scripts/tests/test-link-data.sh`
- Create: `scripts/link-data.sh`

**Step 1: Write the failing test.** Create `scripts/tests/test-link-data.sh` with the harness and the `link-data` section:

```bash
#!/usr/bin/env bash
# Sandbox tests for scripts/link-data.sh. Never touches the real repo or $HOME.
# Run: bash scripts/tests/test-link-data.sh
set -uo pipefail

SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
SANDBOX="$(mktemp -d)"
SANDBOX="$(cd "$SANDBOX" && pwd -P)"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
mkdir -p "$HOME"

pass=0 fail=0
ok()   { pass=$((pass + 1)); echo "  ok   $1"; }
bad()  { fail=$((fail + 1)); echo "  FAIL $1"; }
check() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }

# New sandbox repo per test: copies scripts/, examples/, .gitignore; git init.
new_repo() {
  local r="$SANDBOX/$1"
  mkdir -p "$r"
  cp -R "$SRC_ROOT/scripts" "$r/"
  [[ -d "$SRC_ROOT/examples" ]] && cp -R "$SRC_ROOT/examples" "$r/"
  [[ -f "$SRC_ROOT/.gitignore" ]] && cp "$SRC_ROOT/.gitignore" "$r/"
  (cd "$r" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init)
  echo "$r"
}
seed() { mkdir -p "$1/daily-runs"; echo "a: 1" > "$1/config.yaml"; echo "x" > "$1/daily-runs/2026-01-01.md"; }
link() { bash "$1/scripts/link-data.sh" "${@:2}"; }
field() { grep "^$1=" | head -1 | cut -d= -f2-; }
# --- section: link-data ---
echo "status"
r="$(new_repo status-missing)"
check "missing: mode=missing" test "$(link "$r" --status | field mode)" = missing
mkdir -p "$r/data"; seed "$r/data"
check "in-repo: mode=in-repo" test "$(link "$r" --status | field mode)" = in-repo
check "in-repo: files=2" test "$(link "$r" --status | field files)" = 2

echo "first machine: move"
r="$(new_repo move)"; seed "$r/data"; t="$SANDBOX/sync1/iago-data"
out="$(link "$r" "$t")"; rc=$?
check "exit 0" test "$rc" = 0
check "action=move" test "$(echo "$out" | field action)" = move
check "data is symlink" test -L "$r/data"
check "files moved" test -f "$t/daily-runs/2026-01-01.md"
check "status linked" test "$(link "$r" --status | field mode)" = linked

echo "second machine: link"
r2="$(new_repo second)"
out="$(link "$r2" "$t")"
check "action=link" test "$(echo "$out" | field action)" = link
check "sees config" test -f "$r2/data/config.yaml"

echo "fresh: create"
r="$(new_repo fresh)"; t="$SANDBOX/new/iago"
out="$(link "$r" "$t")"
check "action=create" test "$(echo "$out" | field action)" = create
check "target dir exists" test -d "$t"
check "link resolves" test -d "$r/data"

echo "tilde path"
r="$(new_repo tilde)"
link "$r" "~/Sync/iago" >/dev/null
check "~ expanded under HOME" test "$(readlink "$r/data")" = "$HOME/Sync/iago"
check "status prints ~" test "$(link "$r" --status | field target)" = "~/Sync/iago"

echo "conflict"
r="$(new_repo conflict)"; seed "$r/data"; t="$SANDBOX/conf"; seed "$t"
before="$(cd "$SANDBOX" && find conflict/data conf -type f | sort)"
link "$r" "$t" >/dev/null 2>&1; rc=$?
check "exit 2" test "$rc" = 2
check "nothing changed" test "$(cd "$SANDBOX" && find conflict/data conf -type f | sort)" = "$before"
out="$(link "$r" --force "$t" 2>/dev/null)"
check "--force links" test -L "$r/data"
check "--force backup kept" test -f "$(ls -d "$r"/data.local-backup-*)/config.yaml"

echo "repoint + noop"
r="$(new_repo repoint)"; a="$SANDBOX/A"; b="$SANDBOX/B"; seed "$a"
link "$r" "$a" >/dev/null
check "noop on same target" test "$(link "$r" "$a" | field action)" = noop
out="$(link "$r" "$b")"
check "action=repoint" test "$(echo "$out" | field action)" = repoint
check "points at B" test "$(readlink "$r/data")" = "$b"
check "A untouched" test -f "$a/config.yaml"

echo "refuse inside repo"
r="$(new_repo refuse)"
link "$r" "$r/somewhere" >/dev/null 2>&1; rc=$?
check "exit 3" test "$rc" = 3
check "no link made" test ! -L "$r/data"

echo "broken link"
r="$(new_repo broken)"; t="$SANDBOX/gone"; mkdir -p "$t"
link "$r" "$t" >/dev/null; rm -rf "$t"
link "$r" --status >/dev/null 2>&1; rc=$?
check "status exit 4" test "$rc" = 4
check "mode=broken" test "$(link "$r" --status 2>/dev/null | field mode)" = broken

echo "dry-run changes nothing"
r="$(new_repo dry)"; seed "$r/data"; t="$SANDBOX/dry-target"
out="$(link "$r" --dry-run "$t")"
check "action=move" test "$(echo "$out" | field action)" = move
check "data still a dir" test -d "$r/data" -a ! -L "$r/data"
check "target not created" test ! -e "$t"
# --- end sections ---
echo
echo "passed=$pass failed=$fail"
[[ "$fail" == 0 ]]
```

**Step 2: Run it and confirm it fails.**
`bash scripts/tests/test-link-data.sh`
Expected: many `FAIL` lines (no `scripts/link-data.sh`) and a non-zero exit.

**Step 3: Implement.** Create `scripts/link-data.sh` and make it executable (`chmod +x`):

```bash
#!/usr/bin/env bash
# Point this checkout's data/ at a folder outside the repo (per machine).
# Iago never syncs anything: sync the target folder with any tool you like.
#
# Usage:
#   bash scripts/link-data.sh --status            # where is data/ right now?
#   bash scripts/link-data.sh --dry-run <folder>  # preview, change nothing
#   bash scripts/link-data.sh <folder>            # move/link data/ to <folder>
#   bash scripts/link-data.sh --force <folder>    # on conflict: back up local data/, then link
#
# Output: stable key=value lines (parsed by the iago-data-location skill).
# Exit codes: 0 ok, 1 usage/error, 2 conflict, 3 refused (target inside repo), 4 broken link.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
DATA="$REPO_ROOT/data"

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
}

# Expand ~ and relative paths; resolve the deepest existing ancestor.
abspath() {
  local p="$1"
  case "$p" in
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
    /*) ;;
    *) p="$PWD/$p" ;;
  esac
  p="${p%/}"
  local d="$p" rest=""
  while [[ ! -d "$d" ]]; do
    rest="/$(basename "$d")$rest"
    d="$(dirname "$d")"
  done
  echo "$(cd "$d" && pwd -P)$rest"
}

tilde() {
  local p="$1" home
  home="$(cd "$HOME" 2>/dev/null && pwd -P || echo "$HOME")"
  case "$p" in
    "$home") echo "~" ;;
    "$home"/*) echo "~/${p#"$home"/}" ;;
    *) echo "$p" ;;
  esac
}

# Count real files (ignore Finder/git placeholders).
count_files() {
  [[ -d "$1" ]] || { echo 0; return; }
  find "$1/" -type f ! -name .DS_Store ! -name .gitkeep | wc -l | tr -d ' '
}

kb_of() {
  [[ -d "$1" ]] || { echo 0; return; }
  du -sk "$1/" | cut -f1
}

data_mode() {
  if [[ -L "$DATA" ]]; then
    [[ -d "$DATA" ]] && echo linked || echo broken
  elif [[ -d "$DATA" ]]; then
    echo in-repo
  else
    echo missing
  fi
}

cmd_status() {
  local mode
  mode="$(data_mode)"
  echo "mode=$mode"
  echo "repo=$(tilde "$REPO_ROOT")"
  case "$mode" in
    linked|broken) echo "target=$(tilde "$(readlink "$DATA")")" ;;
    in-repo) echo "target=$(tilde "$DATA")" ;;
    missing) echo "target=" ;;
  esac
  echo "files=$(count_files "$DATA")"
  echo "kb=$(kb_of "$DATA")"
  if [[ "$mode" == broken ]]; then
    echo "hint=Folder not found. Mount/sync it, or run: bash scripts/link-data.sh <folder>" >&2
    return 4
  fi
}

# Decide what linking to $1 would do. Prints action; never changes anything.
plan_action() {
  local target="$1" mode local_n target_n
  if [[ "$target" == "$REPO_ROOT" || "$target" == "$REPO_ROOT"/* ]]; then
    echo refuse; return
  fi
  mode="$(data_mode)"
  local_n="$(count_files "$DATA")"
  target_n="$(count_files "$target")"
  case "$mode" in
    linked|broken)
      if [[ "$(readlink "$DATA")" == "$target" ]]; then echo noop; else echo repoint; fi ;;
    in-repo)
      if (( local_n > 0 && target_n > 0 )); then echo conflict
      elif (( local_n > 0 )); then echo move
      elif (( target_n > 0 )); then echo link
      else echo create
      fi ;;
    missing)
      if (( target_n > 0 )); then echo link; else echo create; fi ;;
  esac
}

print_plan() {
  local action="$1" target="$2"
  echo "action=$action"
  echo "mode=$(data_mode)"
  echo "target=$(tilde "$target")"
  echo "local_files=$(count_files "$DATA")"
  echo "local_kb=$(kb_of "$DATA")"
  echo "target_files=$(count_files "$target")"
  echo "target_kb=$(kb_of "$target")"
}

make_link() {
  ln -sfn "$1" "$DATA"
}

cmd_apply() {
  local target="$1" dry="$2" force="$3" action
  action="$(plan_action "$target")"
  print_plan "$action" "$target"

  case "$action" in
    refuse)
      echo "error: target is inside the repo; choose a folder outside $(tilde "$REPO_ROOT")" >&2
      return 3 ;;
    conflict)
      if [[ "$force" != true ]]; then
        echo "error: both data/ and $(tilde "$target") contain files; nothing changed." >&2
        echo "hint=Pick which copy to keep. --force backs up data/ to data.local-backup-<timestamp>/ and links to the target." >&2
        return 2
      fi ;;
  esac

  [[ "$dry" == true ]] && return 0

  case "$action" in
    noop) ;;
    create|link)
      mkdir -p "$target"
      # In-repo data/ has no real files here (only placeholders): safe to replace.
      [[ -d "$DATA" && ! -L "$DATA" ]] && rm -rf "$DATA"
      make_link "$target" ;;
    move)
      local before after
      before="$(count_files "$DATA")"
      mkdir -p "$target"
      cp -Rp "$DATA/." "$target/"
      after="$(count_files "$target")"
      if [[ "$after" != "$before" ]]; then
        echo "error: copy verification failed ($before files in data/, $after in target); data/ left in place." >&2
        return 1
      fi
      rm -rf "$DATA"
      make_link "$target" ;;
    repoint)
      mkdir -p "$target"
      rm "$DATA"
      make_link "$target" ;;
    conflict)
      local backup
      backup="$DATA.local-backup-$(date +%Y%m%d-%H%M%S)"
      mv "$DATA" "$backup"
      echo "backup=$(tilde "$backup")"
      make_link "$target" ;;
  esac
  echo "result=ok"
}

main() {
  local dry=false force=false status=false target=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status) status=true; shift ;;
      --dry-run) dry=true; shift ;;
      --force) force=true; shift ;;
      -h|--help) usage; return 0 ;;
      -*) echo "error: unknown option: $1" >&2; usage >&2; return 1 ;;
      *)
        [[ -n "$target" ]] && { echo "error: unexpected argument: $1" >&2; return 1; }
        target="$1"; shift ;;
    esac
  done

  if [[ "$status" == true ]]; then cmd_status; return; fi
  if [[ -z "$target" ]]; then usage >&2; return 1; fi
  cmd_apply "$(abspath "$target")" "$dry" "$force"
}

main "$@"
```

**Step 4: Run it and confirm it passes.**
`bash scripts/tests/test-link-data.sh`
Expected: `passed=30 failed=0`.

**Step 5: Commit.**
`git add scripts/link-data.sh scripts/tests/test-link-data.sh && git commit -m "feat: add link-data.sh to point data/ at an external folder"`

---

### Task 2: Ignore a symlinked `data` and the backup folders

**Files:**
- Modify: `.gitignore`
- Delete: `data/.gitkeep` (tracked)
- Test: `scripts/tests/test-link-data.sh`

**Step 1: Failing test.** Insert this section before `# --- end sections ---`:

```bash
# --- section: gitignore ---
echo "gitignore: symlinked data/ never shows in git status"
r="$(new_repo gitignore)"; seed "$r/data"; link "$r" "$SANDBOX/gi-target" >/dev/null
check "git status clean" test -z "$(cd "$r" && git status --porcelain)"
r="$(new_repo gitignore-inrepo)"; seed "$r/data"
check "in-repo data ignored too" test -z "$(cd "$r" && git status --porcelain)"
link "$r" --force "$SANDBOX/gi2" >/dev/null 2>&1; seed "$SANDBOX/gi2"; mkdir -p "$r/data.local-backup-x"; echo y > "$r/data.local-backup-x/f"
check "backup dirs ignored" test -z "$(cd "$r" && git status --porcelain)"
```

**Step 2:** `bash scripts/tests/test-link-data.sh`. Expected: `FAIL git status clean` and `FAIL backup dirs ignored`, because `data/*` doesn't match a symlink named `data`.

**Step 3: Implement.**

```diff
--- a/.gitignore
+++ b/.gitignore
@@ -1,6 +1,6 @@
 # Local job search data (Resume-Matcher pattern)
-data/*
-!data/.gitkeep
+/data
+/data.local-backup-*/
 
 # OS
 .DS_Store
```

Then run `git rm --cached data/.gitkeep`. Use `--cached` so local `data/` contents are never touched.

**Step 4:** `bash scripts/tests/test-link-data.sh`. Expected: `passed=33 failed=0`.

**Step 5:** `git add .gitignore scripts/tests/test-link-data.sh && git commit -m "chore: gitignore /data so a symlinked data folder is never tracked"`. The commit includes the staged `.gitkeep` removal.

> **Upgrade note (README, Task 9):** after this lands, an older checkout (e.g. `git checkout main` before merge) tracks `data/.gitkeep`, and git refuses to write through a `data` symlink ("beyond a symbolic link"). Only switch to old branches with an in-repo `data/`.

---

### Task 3: Broken-link guard for scripts

**Files:**
- Create: `scripts/lib/data-dir.sh`
- Modify: `scripts/run-daily-search.sh`, `scripts/reconcile-config.sh`, `scripts/reconcile-config.py`
- Test: `scripts/tests/test-link-data.sh`

**Step 1: Failing test.** Insert before `# --- end sections ---`:

```bash
# --- section: guard ---
echo "guard: broken link stops scripts"
r="$(new_repo guard)"; t="$SANDBOX/guard-gone"; mkdir -p "$t"; link "$r" "$t" >/dev/null; rm -rf "$t"
bash "$r/scripts/run-daily-search.sh" >/dev/null 2>&1; rc=$?
check "run-daily-search exit 4" test "$rc" = 4
bash "$r/scripts/reconcile-config.sh" >/dev/null 2>&1; rc=$?
check "reconcile-config exit 4" test "$rc" = 4
```

**Step 2:** Run the tests. Expected: `FAIL run-daily-search exit 4` (it currently `mkdir -p`s through the broken link and exits 1), and `FAIL reconcile-config exit 4`.

**Step 3: Implement.** Create `scripts/lib/data-dir.sh`:

```bash
# Sourced by Iago scripts. Fails fast when data/ is a symlink to a folder that
# is not there (sync drive unmounted, folder renamed) instead of silently
# creating a fresh, empty data/.
iago_require_data_dir() {
  local repo="$1" data="$1/data"
  if [[ -L "$data" && ! -d "$data" ]]; then
    echo "error: data -> $(readlink "$data") does not exist." >&2
    echo "  Mount or sync that folder, or point Iago elsewhere:" >&2
    echo "  bash \"$repo/scripts/link-data.sh\" <folder>   (or ask: \"change my Iago data folder\")" >&2
    return 4
  fi
}
```

```diff
--- a/scripts/run-daily-search.sh
+++ b/scripts/run-daily-search.sh
@@ -35,6 +35,9 @@
 
 REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
 DATA_DIR="$REPO_ROOT/data"
+# shellcheck source=lib/data-dir.sh
+source "$REPO_ROOT/scripts/lib/data-dir.sh"
+iago_require_data_dir "$REPO_ROOT" || exit $?
 LOG_DIR="$DATA_DIR/logs"
 mkdir -p "$LOG_DIR" "$DATA_DIR/daily-runs"
 
```

```diff
--- a/scripts/reconcile-config.sh
+++ b/scripts/reconcile-config.sh
@@ -11,4 +11,7 @@
 set -euo pipefail
 
 REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
+# shellcheck source=lib/data-dir.sh
+source "$REPO_ROOT/scripts/lib/data-dir.sh"
+iago_require_data_dir "$REPO_ROOT" || exit $?
 exec python3 "$REPO_ROOT/scripts/reconcile-config.py" "$@"
```

```diff
--- a/scripts/reconcile-config.py
+++ b/scripts/reconcile-config.py
@@ -81,6 +81,15 @@
         print(f"Missing example config: {args.example}", file=sys.stderr)
         return 1
 
+    data_link = root / "data"
+    if data_link.is_symlink() and not data_link.exists():
+        print(
+            f"data -> {data_link.readlink()} does not exist. Mount or sync that folder, "
+            f"or run: bash scripts/link-data.sh <folder>",
+            file=sys.stderr,
+        )
+        return 4
+
     if not args.config.is_file():
         print(
             f"Missing {args.config}. Run: bash scripts/init-data.sh",
```

**Step 4:** Run the tests. Expected: `passed=35 failed=0`.

**Step 5:** `git add scripts/lib scripts/run-daily-search.sh scripts/reconcile-config.sh scripts/reconcile-config.py scripts/tests/test-link-data.sh && git commit -m "feat: fail fast when data/ links to a missing folder"`

---

### Task 4: `init-data.sh` asks for, or accepts, the data folder

**Files:**
- Modify: `scripts/init-data.sh`
- Test: `scripts/tests/test-link-data.sh`

**Step 1: Failing test.** Insert before `# --- end sections ---`:

```bash
# --- section: init-data ---
echo "init-data flags"
r="$(new_repo init-broken)"; t="$SANDBOX/target-init-broken"; mkdir -p "$t"; link "$r" "$t" >/dev/null; rm -rf "$t"
bash "$r/scripts/init-data.sh" --keep-in-repo >/dev/null 2>&1; rc=$?
check "broken link: init-data exit 4" test "$rc" = 4
check "broken link: no empty folder created at target" test ! -e "$t"
r="$(new_repo init-ext)"; t="$SANDBOX/target-init-ext"
bash "$r/scripts/init-data.sh" --data-dir "$t" >/dev/null 2>&1
check "--data-dir links" test -L "$r/data"
check "--data-dir copies templates into target" test -f "$t/config.yaml"
r="$(new_repo init-existing)"; t="$SANDBOX/target-init-existing"; seed "$t"
sum_before="$(cd "$t" && find . -type f -exec cksum {} + | sort)"
bash "$r/scripts/init-data.sh" --data-dir "$t" >/dev/null 2>&1
check "existing config untouched" test "$(cat "$t/config.yaml")" = "a: 1"
check "existing files unchanged" test -z "$(comm -23 <(echo "$sum_before") <(cd "$t" && find . -type f -exec cksum {} + | sort))"
r="$(new_repo init-keep)"
bash "$r/scripts/init-data.sh" --keep-in-repo >/dev/null 2>&1
check "--keep-in-repo makes real dir" test -d "$r/data" -a ! -L "$r/data"
check "--keep-in-repo has config" test -f "$r/data/config.yaml"
r="$(new_repo init-noninteractive)"
bash "$r/scripts/init-data.sh" </dev/null >/dev/null 2>&1
check "no tty defaults to in-repo" test -d "$r/data" -a ! -L "$r/data"
```

**Step 2:** Run the tests. Expected: failures on `--data-dir links`, `--keep-in-repo …` and `broken link: init-data exit 4` (unknown arguments are currently ignored, and the script `mkdir`s through a broken link).

**Step 3: Implement.**

```diff
--- a/scripts/init-data.sh
+++ b/scripts/init-data.sh
@@ -1,6 +1,11 @@
 #!/usr/bin/env bash
 # Copy example templates into data/ for first-time setup.
 # Safe to re-run: skips files that already exist.
+#
+# Usage:
+#   bash scripts/init-data.sh                     # asks where to store data if data/ is missing
+#   bash scripts/init-data.sh --data-dir <folder> # store data outside the repo (see link-data.sh)
+#   bash scripts/init-data.sh --keep-in-repo      # plain gitignored data/ inside the repo
 
 set -euo pipefail
 
@@ -8,6 +13,36 @@
 EXAMPLES="$REPO_ROOT/examples"
 DATA="$REPO_ROOT/data"
 
+# shellcheck source=lib/data-dir.sh
+source "$REPO_ROOT/scripts/lib/data-dir.sh"
+
+data_dir=""
+keep_in_repo=false
+while [[ $# -gt 0 ]]; do
+  case "$1" in
+    --data-dir)
+      data_dir="${2:-}"
+      [[ -n "$data_dir" ]] || { echo "error: --data-dir requires a folder" >&2; exit 1; }
+      shift 2 ;;
+    --keep-in-repo) keep_in_repo=true; shift ;;
+    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
+    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
+  esac
+done
+
+iago_require_data_dir "$REPO_ROOT"
+
+if [[ -n "$data_dir" ]]; then
+  bash "$REPO_ROOT/scripts/link-data.sh" "$data_dir"
+elif [[ ! -e "$DATA" && "$keep_in_repo" != true && -t 0 ]]; then
+  echo "Where should Iago store your job search data?"
+  echo "  Pick a folder your sync tool (Nextcloud, Google Drive, Syncthing...) syncs to use Iago on several computers."
+  read -r -p "Folder path (blank = keep inside this repo): " data_dir
+  if [[ -n "$data_dir" ]]; then
+    bash "$REPO_ROOT/scripts/link-data.sh" "$data_dir"
+  fi
+fi
+
 mkdir -p "$DATA/daily-runs" "$DATA/pipeline-reviews" "$DATA/jds" "$DATA/company-research" "$DATA/interview-prep" "$DATA/resume-feedback" "$DATA/logs"
 
 copy_if_missing() {
```

Behaviour: the interactive prompt appears only when `data` doesn't exist and stdin is a TTY. Non-interactive runs (cron, agents without flags) keep today's in-repo default. Templates are still `copy_if_missing`, so a second machine's existing data is never overwritten.

**Step 4:** Run the tests. Expected: `passed=44 failed=0`.

**Step 5:** `git add scripts/init-data.sh scripts/tests/test-link-data.sh && git commit -m "feat: init-data.sh --data-dir/--keep-in-repo and data folder prompt"`

---

### Task 5: `verify-workspace.sh` reports data location and resume_path portability

**Files:**
- Modify: `scripts/verify-workspace.sh`
- Test: `scripts/tests/test-link-data.sh`

**Step 1: Failing test.** Insert before `# --- end sections ---`:

```bash
# --- section: verify-workspace ---
echo "verify-workspace reports data location and resume_path portability"
r="$(new_repo verify)"; mkdir -p "$r/.cursor/skills/iago-setup"; touch "$r/.cursor/skills/iago-setup/SKILL.md"
link "$r" "$SANDBOX/verify-target" >/dev/null
printf 'profile:\n  resume_path: /Users/x/r.md\n' > "$r/data/config.yaml"
out="$(bash "$r/scripts/verify-workspace.sh" "$r" 2>/dev/null)"
check "data_mode=linked" test "$(echo "$out" | field data_mode)" = linked
check "absolute resume_path flagged" test "$(echo "$out" | field resume_path_portable)" = no
printf 'profile:\n  resume_path: resumes/master.md\n' > "$r/data/config.yaml"
out="$(bash "$r/scripts/verify-workspace.sh" "$r" 2>/dev/null)"
check "relative resume_path ok" test "$(echo "$out" | field resume_path_portable)" = yes
```

**Step 2:** Run the tests. Expected: 3 `FAIL`s (no `data_mode` / `resume_path_portable` lines).

**Step 3: Implement.** Use `sed -E`, not `\|`, because BSD `sed` on macOS doesn't support `\|` in basic regex.

```diff
--- a/scripts/verify-workspace.sh
+++ b/scripts/verify-workspace.sh
@@ -106,6 +106,19 @@
 
 echo "skills_at_repo_root=yes"
 
+# Data folder location (in-repo, linked outside the repo, or broken link).
+bash "$REPO_ROOT/scripts/link-data.sh" --status 2>/dev/null | sed -nE 's/^(mode|target)=/data_\1=/p' || true
+if [[ -L "$REPO_ROOT/data" && ! -d "$REPO_ROOT/data" ]]; then
+  echo "data_hint=Data folder not found. Mount/sync it, or ask: \"change my Iago data folder\"" >&2
+fi
+resume_path="$(sed -n 's/^[[:space:]]*resume_path:[[:space:]]*\([^#]*\).*/\1/p' "$REPO_ROOT/data/config.yaml" 2>/dev/null | head -1 | tr -d "\"' " || true)"
+case "$resume_path" in
+  /*|"~"*) echo "resume_path_portable=no"
+           echo "resume_hint=profile.resume_path is machine-specific; move the resume into data/resumes/ and use a relative path" >&2 ;;
+  "") ;;
+  *) echo "resume_path_portable=yes" ;;
+esac
+
 if [[ "$WORKSPACE_ROOT" == "$REPO_ROOT" ]]; then
   echo "workspace_matches_repo=yes"
   exit 0
```

Exit codes are unchanged. Data and resume lines are informational, and hints go to stderr.

**Step 4:** Run the tests. Expected: `passed=47 failed=0`.

**Step 5:** `git add scripts/verify-workspace.sh scripts/tests/test-link-data.sh && git commit -m "feat: verify-workspace reports data folder and resume_path portability"`

---

### Task 6: Data-relative `profile.resume_path`

**Files:**
- Modify: `examples/config.example.yaml:8`
- Modify: `skills/resume-feedback/WORKFLOW.md` (Master resume resolution), `skills/iago-setup/WORKFLOW.md` (Step 1 placeholder signals, Step 2 Profile, Step 10 validation), `skills/iago-daily/WORKFLOW.md:19`, `skills/iago-pipeline-review/WORKFLOW.md:21`, `skills/company-research/WORKFLOW.md:17`

**Step 1: Verification check (run before editing).**
`grep -rn "Resolve \`profile.resume_path\`" skills/ | wc -l`. Expected: `0`.

**Step 2: Implement.**

`examples/config.example.yaml`:
```diff
-  resume_path: /path/to/your/master-resume.md  # local only; never commit
+  resume_path: resumes/YOUR-RESUME.md  # relative to your data folder (recommended), or ~/… or absolute; never commit
```

`skills/resume-feedback/WORKFLOW.md`: add this paragraph directly above `**Master resume resolution**`. It is the canonical rule, and the other skills already point here.

```markdown
**Resolve `profile.resume_path`:** relative paths are relative to the data folder (`$REPO_ROOT/data/<path>`, which follows the data symlink); `~/…` expands to the user's home; absolute paths are used as-is. Prefer relative (e.g. `resumes/master-resume.md`) so the same config works on every synced machine.
```

`skills/iago-daily/WORKFLOW.md:19`, `skills/iago-pipeline-review/WORKFLOW.md:21`, `skills/company-research/WORKFLOW.md:17`: append to the existing table cell ` (resolve per resume-feedback "Resolve \`profile.resume_path\`")`.

`skills/iago-setup/WORKFLOW.md`:
- Step 1 placeholder signals: replace `` `/path/to/your/master-resume.md` `` with `` `resumes/YOUR-RESUME.md` ``.
- Step 2 Profile: replace `` `profile.resume_path` (absolute path; **verify file exists** before continuing) `` with `` `profile.resume_path` (**verify file exists** before continuing, resolving per resume-feedback "Resolve `profile.resume_path`") ``, and replace `Suggest keeping the resume outside this repo.` with `Suggest copying the resume into the data folder (\`data/resumes/\`) and saving a relative path such as \`resumes/master-resume.md\`: it stays out of git and syncs with the rest of the data. Absolute or \`~/\` paths still work but may not exist on the user's other machines.`
- Step 10 table: `` `profile.resume_path` exists `` becomes `` `profile.resume_path` exists (resolved per the rule above) ``.

**Step 3: Verify.**
- `grep -rn "Resolve \`profile.resume_path\`" skills/ | wc -l`. Expected: `5` or more.
- `grep -n "/path/to/your/master-resume.md" -r skills examples`. Expected: no output.
- `bash scripts/tests/test-link-data.sh | tail -1`. Expected: `passed=47 failed=0`.

**Step 4:** `git add examples/config.example.yaml skills && git commit -m "feat: resolve profile.resume_path relative to the data folder"`

---

### Task 7: `iago-data-location` skill

**Files:**
- Create: `skills/iago-data-location/WORKFLOW.md`
- Create: `.cursor/skills/iago-data-location/SKILL.md`, `.claude/skills/iago-data-location/SKILL.md`, `.hermes/skills/iago-data-location/SKILL.md`

**Step 1: Verification check (should fail).** `bash scripts/verify-workspace.sh "$PWD" >/dev/null; for p in cursor claude hermes; do test -f .$p/skills/iago-data-location/SKILL.md && echo "$p ok" || echo "$p missing"; done`. Expected: 3 × `missing`.

**Step 2: Implement.** `skills/iago-data-location/WORKFLOW.md`:

````markdown
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
````

`.claude/skills/iago-data-location/SKILL.md`:

````markdown
---
name: iago-data-location
description: >-
  Show or change where Iago stores job search data on this computer (in the
  repo, or a folder outside it that the user syncs with any tool). Use when
  the user says where is my iago data, move my data, change data folder, use
  iago on another computer, set up sync, data folder missing, or runs
  /iago-data-location. Does not sync files itself.
---

# Iago data location (Claude Code)

**Mandatory:** Read and follow `$REPO_ROOT/skills/iago-data-location/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.claude/skills/iago-data-location/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.claude/skills` |
| Global skill symlink | `readlink -f "$HOME/.claude/skills/iago-data-location"` → `REPO_ROOT` = parent of `.claude/skills` on resolved path |
| Nested under parent workspace | Find `scripts/link-data.sh` in a subfolder; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

## Claude Code-specific

- Ask multi-choice questions in chat (pick folder / type path / keep in repo).
- Run scripts with the Bash tool on the user's behalf; do not ask the user to type commands.
- After `install-skills.sh --platform claude` (or `--platform both`), restart or reload the Claude Code session if the skill does not appear.
````

`.cursor/skills/iago-data-location/SKILL.md`: identical except the heading is `# Iago data location (Cursor)`, the table uses `.cursor/skills` and `$HOME/.cursor/skills/iago-data-location`, and the platform section is:

```markdown
## Cursor-specific

- Ask multi-choice questions in chat (pick folder / type path / keep in repo).
- Run scripts in the integrated terminal on the user's behalf; do not ask the user to type commands.
```

`.hermes/skills/iago-data-location/SKILL.md`: identical except the heading is `# Iago data location (Hermes)`, the table uses `.hermes/skills` and `$HOME/.hermes/skills/iago-data-location`, and the platform section is:

```markdown
## Hermes-specific

- Ask multi-choice questions as chat options. Hermes may render selectable choices in desktop mode, but always provide complete textual options for compatibility.
- New skills are discovered by new Hermes sessions after `install-skills.sh --platform hermes`; no reload needed.
```

**Step 3: Verify.**
- Re-run the Step 1 loop. Expected: 3 × `ok`.
- `H=$(mktemp -d); HOME="$H" HERMES_HOME="$H/.hermes" bash scripts/install-skills.sh --platform both >/dev/null; ls "$H"/.cursor/skills/iago-data-location/SKILL.md "$H"/.claude/skills/iago-data-location/SKILL.md "$H"/.hermes/skills/iago-data-location/SKILL.md`. Expected: 3 paths listed, no errors.
- `head -8 .claude/skills/iago-data-location/SKILL.md`. Expected: valid frontmatter with `name: iago-data-location`.

**Step 4:** `git add skills/iago-data-location .cursor/skills/iago-data-location .claude/skills/iago-data-location .hermes/skills/iago-data-location && git commit -m "feat: add iago-data-location skill to view/change the data folder from chat"`

---

### Task 8: Onboarding asks for the data folder (`iago-setup`)

**Files:**
- Modify: `skills/iago-setup/WORKFLOW.md`
- Modify: `.cursor/skills/iago-setup/SKILL.md`, `.claude/skills/iago-setup/SKILL.md`, `.hermes/skills/iago-setup/SKILL.md` (description only)

**Step 1: Verification check (should fail).** `grep -c "0b. Choose data folder" skills/iago-setup/WORKFLOW.md`. Expected: `0`.

**Step 2: Implement.** In `skills/iago-setup/WORKFLOW.md`, insert this new section between `### 0. Verify workspace and skills` (after the "Combined workspace note" paragraph) and `### 1. Detect state`:

```markdown
### 0b. Choose data folder

Decide where this computer keeps Iago data **before** any data file is created. Follow `$REPO_ROOT/skills/iago-data-location/WORKFLOW.md` (steps 2–6) for the status → pick → preview → confirm → link flow; do not duplicate its logic here.

1. Run `bash "$REPO_ROOT/scripts/link-data.sh" --status`.
2. Branch on `mode`:

   | `mode` | Action |
   |--------|--------|
   | `missing` (fresh clone) | **Always ask:** "Where should Iago keep your job search data? To use Iago on more than one computer, pick a folder your sync tool (Nextcloud, Google Drive, Syncthing, …) already syncs. Or keep it inside the Iago repo." Choices: **Pick a folder** (recommended) / **Type a path** / **Keep in repo**. Remember the choice for step 1 (`--data-dir "<folder>"` or `--keep-in-repo`). For a folder, preview with `--dry-run` and confirm, but let step 1's `init-data.sh --data-dir` do the linking. |
   | `in-repo` with files | Say where the data is and offer **Move to a folder outside the repo** (run the iago-data-location flow now) or **Keep as is**. Never force a move. |
   | `linked` | Say "Using `<target>`." and continue without asking. |
   | `broken` | Stop setup. Offer **Pick a different folder** or **I'll reconnect the sync folder**. Never initialize an empty folder at the missing path. |

3. **Second computer:** if the chosen folder already contains `config.yaml`, say "Found existing Iago data (last updated <mtime of applications.yaml>). Linking to it; nothing will be overwritten." In step 1, default to **Update config**.
4. Typed paths may use `~` or be relative; show the resolved path from the dry-run `target=` line back to the user before confirming.
```

Replace the code block in `### 1. Detect state`:

```diff
-If any are missing, run:
-
-```bash
-bash "$REPO_ROOT/scripts/init-data.sh"
-```
+If any are missing, run `init-data.sh` with the choice from step 0b (never bare, so it does not prompt a second time):
+
+```bash
+bash "$REPO_ROOT/scripts/init-data.sh" --data-dir "<chosen folder>"   # or: --keep-in-repo
+```
+
+If 0b linked to a folder that already has a filled-in `config.yaml` (another machine), default to **Update config**, not **Fresh setup**.
```

Step 10, replace the reminder line:

```diff
-Remind user: all output stays in gitignored `data/`. After setup, run `git status` to confirm nothing under `data/` is staged.
+Remind user where their data lives, using `link-data.sh --status`: e.g. "Your data is stored in `~/Nextcloud/iago-data`, outside the git repo" (or "in the repo's gitignored `data/` folder"). After setup, run `git status` to confirm nothing under `data/` is staged.
```

Step 12 "Summarize" list, add after the `Path to $REPO_ROOT/data/config.yaml` bullet:

```markdown
- Data folder location (from `link-data.sh --status`). If external: "On another computer, clone Iago and run setup (or ask *change my Iago data folder*) and pick the same synced folder."
```

Files table, add a row:

```markdown
| `$REPO_ROOT/scripts/link-data.sh` | Data folder status / link (step 0b; shared with `iago-data-location`) |
```

In all three `iago-setup/SKILL.md` wrappers, update the description first line from `Guided job search onboarding that initializes gitignored data/ files and` to `Guided job search onboarding that picks the data folder, initializes data/ files, and`. Keep the line wrapping consistent.

**Step 3: Verify.**
- `grep -c "0b. Choose data folder" skills/iago-setup/WORKFLOW.md`. Expected: `1`.
- `grep -n 'init-data.sh"$' skills/iago-setup/WORKFLOW.md`. Expected: no output (no bare call left).
- `grep -c "picks the data folder" .cursor/skills/iago-setup/SKILL.md .claude/skills/iago-setup/SKILL.md .hermes/skills/iago-setup/SKILL.md`. Expected: `1` each.

**Step 4:** `git add skills/iago-setup .cursor/skills/iago-setup .claude/skills/iago-setup .hermes/skills/iago-setup && git commit -m "feat: iago-setup asks where to store data before initializing"`

---

### Task 9: README

**Files:** Modify `README.md`

**Step 1: Implement.**

In "### 2. Run setup in Cursor", replace the paragraph starting `The setup skill initializes` with:

```markdown
Setup first asks **where to store your data**: pick a folder your sync tool already syncs (Nextcloud, Google Drive, Syncthing, …) to use Iago on several computers, or keep it inside the repo. It then initializes the data folder and walks you through location, role priorities, resume path, search boards, and watch list, and writes `data/config.yaml`.
```

In "### 3. Run your first search", in the **Manual alternative** line, replace `run \`bash scripts/init-data.sh\`` with `run \`bash scripts/init-data.sh\` (it asks where to store data; or pass \`--data-dir <folder>\` / \`--keep-in-repo\`)`.

Replace the whole "### Local data" intro sentence (`Following the same pattern as … inside the repo.`) with:

```markdown
Personal files live in `data/`, which git always ignores. By default that is a folder inside the repo; you can instead point it at a folder anywhere on this machine (see [Storing data outside the repo](#storing-data-outside-the-repo)).
```

Directly after the "### Local data" section's last line (`Nothing under \`data/\` is committed…`), add:

```markdown
### Storing data outside the repo

Use this to sync your job search between computers with any tool, without the data ever being inside the git checkout.

- **In chat:** "Change my Iago data folder" (or `/iago-data-location`). It shows where data is now, lets you pick a folder, previews the change, and asks before doing anything.
- **Terminal:** `bash scripts/link-data.sh <folder>` (`--status` to check, `--dry-run` to preview).

On the first computer, your existing `data/` is moved into the folder. On each other computer, clone Iago and pick that computer's copy of the synced folder; paths can differ per machine (e.g. `~/Nextcloud/iago-data` on a Mac, `~/sync/iago-data` on Linux). Iago links to existing data and never overwrites it. If both places already contain data, nothing changes until you choose which to keep.

Notes:
- Iago does not sync anything; your sync tool does.
- Sync only the data folder. Keep the repo itself out of synced folders: syncing `.git` causes "conflicted copy" files and corrupt repos.
- If the synced folder is missing (drive not mounted), Iago scripts stop with a message instead of starting an empty data folder.
- Store your resume in the data folder (e.g. `resumes/master-resume.md`) and use that relative `profile.resume_path` so it works on every computer.
- macOS and Linux. On Windows, run Iago under WSL.
- Checking out an old Iago version (before this feature) while `data` is a link may fail: git will not write `data/.gitkeep` through a symlink.
```

In "## Repository Layout": add `    iago-data-location/` under `skills/`, `.claude/skills/` and `.hermes/skills/`, and `    iago-data-location/            # Data folder location; /iago-data-location` under `.cursor/skills/`. Change `data/  # Your local state (gitignored)` to `data/  # Your local state (gitignored; folder or per-machine link)`, and add `link-data.sh` to the `scripts/` list.

**Step 2: Verify.** `grep -c "iago-data-location" README.md` gives at least `5`, and `grep -n "#storing-data-outside-the-repo" README.md` returns 1 line. Render-check the anchor in a Markdown preview.

**Step 3:** `git add README.md && git commit -m "docs: README for external data folder"`

---

### Task 10: Full verification

**Files:** none

1. `bash scripts/tests/test-link-data.sh`. Expected: `passed=47 failed=0`.
2. `bash -n scripts/*.sh scripts/lib/*.sh scripts/tests/*.sh && python3 -m py_compile scripts/reconcile-config.py && echo syntax-ok`. Expected: `syntax-ok`.
3. If available: `shellcheck scripts/link-data.sh scripts/lib/data-dir.sh scripts/init-data.sh scripts/tests/test-link-data.sh`.
4. `bash scripts/verify-workspace.sh "$PWD"`. Expected: `data_mode=in-repo`, plus `resume_path_portable=no` on this machine (absolute path today).
5. `git status --short`. Expected: nothing under `data/`, and only the two pre-existing untracked `.hermes/skills/iago-daily/…` entries.
6. **Manual, per platform (Cursor, Claude Code, Hermes)** against a scratch clone (`git clone . /tmp/iago-scratch`):
   - "Where is my Iago data?" reports `missing` or in-repo correctly.
   - "Move my Iago data to /tmp/iago-scratch-data" shows a preview, asks, links, and confirms.
   - "Set up job search" on a fresh scratch clone runs step 0b first. Pick an empty folder, then repeat on a second fresh clone picking the same folder. It should report existing data and default to **Update config**.

**Commit:** none

---

### Task 11 (user, after merge): migrate this machine

Not part of the branch. Do this once the feature is merged:

1. Move the repo out of the synced Obsidian folder, e.g. `~/git-repos/iago` (a fresh `git clone` is cleanest).
2. In chat: "Change my Iago data folder", then pick the synced folder (e.g. a Nextcloud folder). If you're doing this from the old checkout, its real `data/` is moved there.
3. Change `profile.resume_path` to a data-relative path, or rely on `master_resume_source: api`.
4. Optional cleanup in the data folder: `__pycache__/`, `_*.py`, `*.bak.*`, `* (conflicted copy *)*`.
5. On each other computer: clone the repo, then "Set up job search" or "Change my Iago data folder", and pick that machine's copy of the synced folder.

---

## Execution

Plan saved to `docs/plans/2026-11-25-external-data-dir.md`. Options:

1. **Subagent-driven:** one fresh subagent per task, with spec and quality review between tasks.
2. **Manual:** you run the tasks yourself.

---

## Post-review fixes

1. Inside-repo refusal: `abspath` lexically normalises the non-existing tail (`.`, `..`, repeated/trailing `/`) and the check compares inodes (`-ef`) of every existing ancestor, so `nope/../repo/...` and case variants are refused; re-checked after `mkdir -p`, before any copy/delete.
2. Targets that contain the repo (parent, `~`, `..`, `/`) are refused with exit 3; refused targets are never counted.
3. `link-data.sh` records the folder in `git config --local iago.dataDir`; the guard and `--status` report `unlinked` (exit 4) when `data` is not linked to it (e.g. after checking out an old commit), with a `configured=` status key; re-running `link-data.sh <configured>` recovers.
4. Moves copy into `<target>.iago-partial.<pid>`, verify with `diff -rq` plus file count, move into place, and only then remove `data/`; failures remove nothing and name the staging folder.
5. A regular file named `data` is reported as `mode=other` (exit 1) and never overwritten.
6. `count_files` counts symlinks, so a `data/` holding only symlinks is moved, not deleted.
7. `verify-workspace.sh` treats `~/…` `resume_path` as portable; only absolute paths are flagged.
8. `verify-workspace.sh` reuses `link-data.sh --status` and the shared hint wording in `scripts/lib/data-dir.sh`; `init-data.sh` calls the guard as `|| exit $?`.
9. `init-data.sh` rejects `--data-dir` together with `--keep-in-repo` (exit 1).
10. `reconcile-config.py` uses `os.readlink` (works before Python 3.9).
11. Tests added for `--status` exit 0 (missing/in-repo/linked), dry-run of every action changing nothing (conflict exits 2), and byte-identical moves.

### Final-review fixes

12. After the final `mv` into the target, the move is re-verified (staging path gone, `diff -rq data/ <target>` clean, counts match); otherwise exit 1 with `data/` intact and the error names the copy in the target (covers a sync client re-creating the target between `rmdir` and `mv`).
13. `data/` is renamed aside to `data.iago-moved.<pid>` (atomic, same folder), then linked and recorded, then deleted. A failed delete is a warning plus `leftover=<path>` with exit 0; a failed rename aborts with `data/` intact. `/data.iago-moved.*/` is gitignored.
14. Moves fail (before the target is touched) when relative symlinks in `data/` would dangle from the new location; links that were already dangling are allowed.
15. `noop` records `iago.dataDir` whenever it is missing or does not match the target.
16. `iago.dataDir` is only read or written when `git rev-parse --show-toplevel` is the Iago folder itself (shared `iago_own_git_repo` helper in `scripts/lib/data-dir.sh`), so a copy without `.git` never uses an enclosing repo's config.
17. Worktrees share `iago.dataDir` (`--local`); documented in README notes that each worktree must link to the same folder.
18. A target holding only `.gitkeep`/`.DS_Store` files and empty folders is cleared of those before the move (only when it has no real files).
19. No lock (YAGNI); README notes say not to change the data folder while a daily search runs.
20. `upgrade-iago-version.sh` expands its possibly-empty `reconcile_args` with `${a[@]+"${a[@]}"}` (bash 3.2 `set -u`); sandbox test added. Other array expansions in `scripts/` were already guarded or never empty.
21. Copy verification compares symlinks as links (`diff -rq --no-dereference`, probed): GNU diff failed moves on any already-dangling symlink and Apple diff silently skipped symlinks.
22. The renamed-aside `data/` is only deleted if it still matches the linked folder; otherwise it is kept, reported as `leftover=`, and the warning says it has newer changes (closes the write-during-move window). `--status` lists every `data.iago-moved.*` as `leftover=`.
23. Folder paths containing a newline are refused (exit 1); `abspath` would otherwise truncate them.
24. `make_link` confirms `data` is a link to the target; if `data/` was re-created as a real folder, it removes the nested link, fails, and the move rolls back (an empty re-created `data/` is removed first).
25. Placeholder cleanup only deletes zero-byte `.gitkeep` files.
