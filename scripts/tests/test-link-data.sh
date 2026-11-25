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
# --- section: gitignore ---
echo "gitignore: symlinked data/ never shows in git status"
r="$(new_repo gitignore)"; seed "$r/data"; link "$r" "$SANDBOX/gi-target" >/dev/null
check "git status clean" test -z "$(cd "$r" && git status --porcelain)"
r="$(new_repo gitignore-inrepo)"; seed "$r/data"
check "in-repo data ignored too" test -z "$(cd "$r" && git status --porcelain)"
link "$r" --force "$SANDBOX/gi2" >/dev/null 2>&1; seed "$SANDBOX/gi2"; mkdir -p "$r/data.local-backup-x"; echo y > "$r/data.local-backup-x/f"
check "backup dirs ignored" test -z "$(cd "$r" && git status --porcelain)"
# --- section: guard ---
echo "guard: broken link stops scripts"
r="$(new_repo guard)"; t="$SANDBOX/guard-gone"; mkdir -p "$t"; link "$r" "$t" >/dev/null; rm -rf "$t"
bash "$r/scripts/run-daily-search.sh" >/dev/null 2>&1; rc=$?
check "run-daily-search exit 4" test "$rc" = 4
bash "$r/scripts/reconcile-config.sh" >/dev/null 2>&1; rc=$?
check "reconcile-config exit 4" test "$rc" = 4
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
# --- section: refuse-overlap ---
echo "refuse: '..' in a non-existing path segment cannot sneak inside the repo"
r="$(new_repo refdots)"; seed "$r/data"
link "$r" "$SANDBOX/nope/../refdots/data/sub" >/dev/null 2>&1; rc=$?
check "dots: exit 3" test "$rc" = 3
check "dots: data still a real dir" test -d "$r/data" -a ! -L "$r/data"
check "dots: no data/sub created" test ! -e "$r/data/sub"
check "dots: files intact" test -f "$r/data/daily-runs/2026-01-01.md"
link "$r" "$SANDBOX/nope2/./../refdots//x/" >/dev/null 2>&1; rc=$?
check "dots+slashes: exit 3" test "$rc" = 3
mkdir -p "$SANDBOX/casecheck"
if [[ -d "$SANDBOX/CASECHECK" ]]; then
  echo "refuse: case variant of the repo path (case-insensitive filesystem)"
  r="$(new_repo refcase)"; seed "$r/data"
  link "$r" "$SANDBOX/REFCASE/elsewhere" >/dev/null 2>&1; rc=$?
  check "case: exit 3" test "$rc" = 3
  check "case: data still a real dir" test -d "$r/data" -a ! -L "$r/data"
  check "case: nothing created in repo" test ! -e "$r/elsewhere"
else
  echo "  skip case-variant test (case-sensitive filesystem)"
fi
echo "refuse: folder that contains the repo"
r="$(new_repo parent/inner)"
before="$(find "$SANDBOX/parent" | sort)"
link "$r" "$SANDBOX/parent" >/dev/null 2>&1; rc=$?
check "parent: exit 3" test "$rc" = 3
link "$r" "$r/.." >/dev/null 2>&1; rc=$?
check "'..': exit 3" test "$rc" = 3
link "$r" "$r" >/dev/null 2>&1; rc=$?
check "repo itself: exit 3" test "$rc" = 3
link "$r" / >/dev/null 2>&1; rc=$?
check "'/': exit 3" test "$rc" = 3
check "parent: no data link" test ! -L "$r/data"
check "parent: nothing written" test "$(find "$SANDBOX/parent" | sort)" = "$before"
bash "$r/scripts/init-data.sh" --data-dir "$SANDBOX/parent" >/dev/null 2>&1; rc=$?
check "init-data --data-dir parent: fails" test "$rc" != 0
check "init-data: no config.yaml spewed into parent" test ! -e "$SANDBOX/parent/config.yaml"
# --- end sections ---
echo
echo "passed=$pass failed=$fail"
[[ "$fail" == 0 ]]
