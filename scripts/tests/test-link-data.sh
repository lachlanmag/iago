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
# --- end sections ---
echo
echo "passed=$pass failed=$fail"
[[ "$fail" == 0 ]]
