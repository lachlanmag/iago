#!/usr/bin/env bash
# Sandbox tests for scripts/link-data.sh. Never touches the real repo or $HOME.
# Run: bash scripts/tests/test-link-data.sh
set -uo pipefail

SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
SANDBOX="$(mktemp -d)"
SANDBOX="$(cd "$SANDBOX" && pwd -P)"
trap 'chmod -R u+rwX "$SANDBOX" 2>/dev/null; rm -rf "$SANDBOX"' EXIT
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
# --- section: move-staging ---
if [[ "$(id -u)" == 0 ]]; then
  echo "  skip failed-move test (running as root: chmod 000 is not enforced)"
else
  echo "move: copy failure leaves data/ intact and the target clean"
  r="$(new_repo movefail)"; seed "$r/data"; echo "s" > "$r/data/secret.yaml"; chmod 000 "$r/data/secret.yaml"
  t="$SANDBOX/movefail-target"
  err="$(link "$r" "$t" 2>&1 >/dev/null)"; rc=$?
  chmod 644 "$r/data/secret.yaml"
  check "failed move: exit 1" test "$rc" = 1
  check "failed move: data still a real dir" test -d "$r/data" -a ! -L "$r/data"
  check "failed move: all files still in data/" test "$(find "$r/data" -type f | wc -l | tr -d ' ')" = 3
  check "failed move: error names the staging folder" grep -q "movefail-target.iago-partial" <<< "$err"
  check "failed move: no partial files at target" test -z "$(find "$t" -type f 2>/dev/null)"
  check "failed move: no config recorded" test -z "$(git -C "$r" config --local --get iago.dataDir)"
  chmod -R u+rwX "$SANDBOX"/movefail-target.iago-partial.* 2>/dev/null
fi
echo "move: into an existing empty folder (with .DS_Store)"
r="$(new_repo moveempty)"; seed "$r/data"; t="$SANDBOX/moveempty-target"; mkdir -p "$t"; touch "$t/.DS_Store"
link "$r" "$t" >/dev/null 2>&1; rc=$?
check "empty target: exit 0" test "$rc" = 0
check "empty target: linked" test -L "$r/data"
check "empty target: files present" test -f "$t/daily-runs/2026-01-01.md"
check "empty target: no staging left" test -z "$(ls -d "$t".iago-partial.* 2>/dev/null)"
# --- section: configured ---
cfg() { git -C "$1" config --local --get iago.dataDir; }
echo "configured: link-data records this machine's folder in git config"
r="$(new_repo cfg-create)"; t="$SANDBOX/cfg-create-target"
link "$r" "$t" >/dev/null
check "create sets iago.dataDir" test "$(cfg "$r")" = "$t"
check "status configured= (tilde form)" test "$(HOME="$SANDBOX" link "$r" --status | field configured)" = "~/cfg-create-target"
b="$SANDBOX/cfg-create-B"; link "$r" "$b" >/dev/null
check "repoint updates iago.dataDir" test "$(cfg "$r")" = "$b"
git -C "$r" config --local --unset iago.dataDir
link "$r" "$b" >/dev/null
check "noop sets iago.dataDir when unset" test "$(cfg "$r")" = "$b"
r="$(new_repo cfg-move)"; seed "$r/data"; t="$SANDBOX/cfg-move-target"; link "$r" "$t" >/dev/null
check "move sets iago.dataDir" test "$(cfg "$r")" = "$t"
r="$(new_repo cfg-force)"; seed "$r/data"; t="$SANDBOX/cfg-force-target"; seed "$t"; link "$r" --force "$t" >/dev/null 2>&1
check "conflict --force sets iago.dataDir" test "$(cfg "$r")" = "$t"
r="$(new_repo cfg-status)"
check "status configured= empty when unset" test "$(link "$r" --status | grep -c '^configured=$')" = 1
r="$(new_repo cfg-dry)"; link "$r" --dry-run "$SANDBOX/cfg-dry-target" >/dev/null
check "dry-run records nothing" test -z "$(cfg "$r")"

echo "configured: git checkout of an old commit must not cause split-brain"
r="$(new_repo checkout)"; main_branch="$(git -C "$r" symbolic-ref --short HEAD)"
(cd "$r" && git checkout -qb old && printf 'data/*\n!data/.gitkeep\n' > .gitignore && mkdir -p data && touch data/.gitkeep \
  && git add .gitignore data/.gitkeep && git -c user.email=t@t -c user.name=t commit -qm old && git checkout -q "$main_branch")
t="$SANDBOX/checkout-target"; seed "$t"
link "$r" "$t" >/dev/null
(cd "$r" && git checkout -q old 2>/dev/null; git checkout -q "$main_branch" 2>/dev/null)
check "external files survive the checkouts" test -f "$t/daily-runs/2026-01-01.md"
bash "$r/scripts/run-daily-search.sh" >/dev/null 2>"$SANDBOX/checkout.err"; rc=$?
check "run-daily-search exit 4" test "$rc" = 4
check "no fresh data/ dir created" test ! -d "$r/data" -o -L "$r/data"
check "error names the configured folder" grep -q "link-data.sh \"$t\"" "$SANDBOX/checkout.err"
bash "$r/scripts/init-data.sh" --keep-in-repo >/dev/null 2>&1; rc=$?
check "init-data exit 4" test "$rc" = 4
check "init-data created no data/" test ! -d "$r/data" -o -L "$r/data"
link "$r" --status >/dev/null 2>&1; rc=$?
check "status exit 4" test "$rc" = 4
check "status mode=unlinked" test "$(link "$r" --status 2>/dev/null | field mode)" = unlinked
link "$r" "$t" >/dev/null 2>&1; rc=$?
check "re-link exit 0" test "$rc" = 0
check "re-link restores symlink" test -L "$r/data" -a "$(readlink "$r/data")" = "$t"
check "status linked after re-link" test "$(link "$r" --status | field mode)" = linked
echo "configured: old checkout left a placeholder-only data/ dir"
r="$(new_repo placeholder)"; t="$SANDBOX/placeholder-target"; seed "$t"; link "$r" "$t" >/dev/null
rm "$r/data"; mkdir "$r/data"; touch "$r/data/.gitkeep" "$r/data/.DS_Store"
check "placeholder dir: status unlinked" test "$(link "$r" --status 2>/dev/null | field mode)" = unlinked
bash "$r/scripts/run-daily-search.sh" >/dev/null 2>&1; rc=$?
check "placeholder dir: run-daily-search exit 4" test "$rc" = 4
out="$(link "$r" "$t" 2>/dev/null)"; rc=$?
check "placeholder dir: action=link" test "$(echo "$out" | field action)" = link
check "placeholder dir: relinked" test -L "$r/data" -a "$(readlink "$r/data")" = "$t"
# --- section: minor ---
echo "data is a regular file: mode=other"
r="$(new_repo other)"; echo "precious" > "$r/data"; t="$SANDBOX/other-target"
out="$(link "$r" --status 2>/dev/null)"; rc=$?
check "other: status mode=other" test "$(echo "$out" | field mode)" = other
check "other: status exit 1" test "$rc" = 1
link "$r" "$t" >/dev/null 2>&1; rc=$?
check "other: apply exit 1" test "$rc" = 1
check "other: file untouched" test -f "$r/data" -a "$(cat "$r/data")" = precious
check "other: target not created" test ! -e "$t"
echo "data/ with only symlinks is not empty"
r="$(new_repo symonly)"; mkdir -p "$r/data"; echo hi > "$SANDBOX/symonly-real.md"; ln -s "$SANDBOX/symonly-real.md" "$r/data/resume.md"
t="$SANDBOX/symonly-target"
check "symlink-only: action=move" test "$(link "$r" --dry-run "$t" | field action)" = move
link "$r" "$t" >/dev/null 2>&1; rc=$?
check "symlink-only: exit 0" test "$rc" = 0
check "symlink-only: symlink moved" test -L "$t/resume.md"
echo "verify-workspace: ~ resume_path is portable, hints match the guard"
r="$(new_repo verify2)"; mkdir -p "$r/.cursor/skills/iago-setup"; touch "$r/.cursor/skills/iago-setup/SKILL.md"
t="$SANDBOX/verify2-target"; link "$r" "$t" >/dev/null
printf 'profile:\n  resume_path: ~/x.md\n' > "$r/data/config.yaml"
out="$(bash "$r/scripts/verify-workspace.sh" "$r" 2>/dev/null)"
check "~ resume_path portable" test "$(echo "$out" | field resume_path_portable)" = yes
rm "$r/data"
out="$(bash "$r/scripts/verify-workspace.sh" "$r" 2>"$SANDBOX/v2.err")"
check "verify: data_mode=unlinked" test "$(echo "$out" | field data_mode)" = unlinked
check "verify: data_configured reported" test "$(echo "$out" | field data_configured)" = "$t"
guard_msg="$(bash "$r/scripts/reconcile-config.sh" 2>&1 >/dev/null | sed -n 's/^error: //p')"
check "verify: unlinked hint matches guard wording" test "$(field data_hint < "$SANDBOX/v2.err")" = "$guard_msg"
ln -s "$SANDBOX/verify2-gone" "$r/data"; git -C "$r" config --local --unset iago.dataDir
bash "$r/scripts/verify-workspace.sh" "$r" >/dev/null 2>"$SANDBOX/v2.err"
guard_msg="$(bash "$r/scripts/reconcile-config.sh" 2>&1 >/dev/null | sed -n 's/^error: //p')"
check "verify: broken hint matches guard wording" test "$(field data_hint < "$SANDBOX/v2.err")" = "$guard_msg"
echo "init-data: --data-dir and --keep-in-repo together"
r="$(new_repo init-both)"
bash "$r/scripts/init-data.sh" --data-dir "$SANDBOX/init-both-target" --keep-in-repo >/dev/null 2>&1; rc=$?
check "both flags: exit 1" test "$rc" = 1
check "both flags: no data/" test ! -e "$r/data" -a ! -L "$r/data"
check "both flags: no target" test ! -e "$SANDBOX/init-both-target"
if python3 -c 'import ruamel.yaml' 2>/dev/null; then
  echo "reconcile-config.py: broken link check (python directly)"
  r="$(new_repo pyguard)"; ln -s "$SANDBOX/pyguard-gone" "$r/data"
  err="$(python3 "$r/scripts/reconcile-config.py" 2>&1)"; rc=$?
  check "python: exit 4" test "$rc" = 4
  check "python: names the missing folder" grep -q "pyguard-gone" <<< "$err"
else
  echo "  skip python guard test (ruamel.yaml not installed)"
fi
# --- section: spec-gaps ---
snap() { { find "$@" 2>/dev/null | sort; readlink "$1/data"; git -C "$1" config --local --get iago.dataDir; } 2>/dev/null; }
echo "status exits 0 for healthy modes"
r="$(new_repo st0)"
link "$r" --status >/dev/null; check "missing: exit 0" test "$?" = 0
mkdir "$r/data"; seed "$r/data"
link "$r" --status >/dev/null; check "in-repo: exit 0" test "$?" = 0
link "$r" "$SANDBOX/st0-target" >/dev/null
link "$r" --status >/dev/null; check "linked: exit 0" test "$?" = 0
echo "dry-run reports the action and changes nothing"
dry_case() { # name repo target expected_action expected_rc
  local before out rc
  before="$(snap "$2" "$3")"
  out="$(link "$2" --dry-run "$3" 2>/dev/null)"; rc=$?
  check "dry $1: action=$4" test "$(echo "$out" | field action)" = "$4"
  check "dry $1: exit $5" test "$rc" = "$5"
  check "dry $1: nothing changed" test "$(snap "$2" "$3")" = "$before"
}
r="$(new_repo dry-link)"; t="$SANDBOX/dry-link-t"; seed "$t"; dry_case link "$r" "$t" link 0
r="$(new_repo dry-create)"; dry_case create "$r" "$SANDBOX/dry-create-t" create 0
r="$(new_repo dry-repoint)"; link "$r" "$SANDBOX/dry-rp-a" >/dev/null; dry_case repoint "$r" "$SANDBOX/dry-rp-b" repoint 0
r="$(new_repo dry-noop)"; link "$r" "$SANDBOX/dry-noop-a" >/dev/null; dry_case noop "$r" "$SANDBOX/dry-noop-a" noop 0
r="$(new_repo dry-refuse)"; seed "$r/data"; dry_case refuse "$r" "$r/inside" refuse 3
r="$(new_repo dry-conflict)"; seed "$r/data"; t="$SANDBOX/dry-conflict-t"; seed "$t"; dry_case conflict "$r" "$t" conflict 2
echo "move preserves content exactly"
r="$(new_repo move-exact)"; seed "$r/data"; mkdir -p "$r/data/jds/deep"; printf 'line1\nline2\n' > "$r/data/jds/deep/x.md"; touch "$r/data/.hidden"
cp -Rp "$r/data" "$SANDBOX/move-exact-copy"; t="$SANDBOX/move-exact-target"
link "$r" "$t" >/dev/null
check "move: content identical" diff -r "$SANDBOX/move-exact-copy" "$t"
# --- section: final-review ---
# PATH shims live inside the sandbox only.
shim() { # dir name body (body may use $REAL for the real command)
  mkdir -p "$1"
  printf '#!/bin/bash\nREAL=%s\n%s\n' "$(command -v "$2")" "$3" > "$1/$2"
  chmod +x "$1/$2"
}
echo "move: target re-created between rmdir and mv (sync client race)"
r="$(new_repo race)"; seed "$r/data"; t="$SANDBOX/race-sync/iago"; mkdir -p "$t"
shim "$SANDBOX/shim-race" rmdir '"$REAL" "$@" && mkdir "$@"'
err="$(PATH="$SANDBOX/shim-race:$PATH" bash "$r/scripts/link-data.sh" "$t" 2>&1 >"$SANDBOX/race.out")"; rc=$?
check "race: exit 1" test "$rc" = 1
check "race: no result=ok" test -z "$(grep '^result=ok' "$SANDBOX/race.out")"
check "race: data still a real dir" test -d "$r/data" -a ! -L "$r/data"
check "race: all files still in data/" test "$(find "$r/data" -type f | wc -l | tr -d ' ')" = 2
check "race: error names the target" grep -q "race-sync/iago" <<< "$err"
check "race: no config recorded" test -z "$(git -C "$r" config --local --get iago.dataDir)"
if [[ "$(id -u)" == 0 ]]; then
  echo "  skip undeletable-source test (running as root)"
else
  echo "move: deleting data/ fails midway after a verified copy"
  r="$(new_repo rmfail)"; seed "$r/data"; mkdir -p "$r/data/locked"; echo keep > "$r/data/locked/f.md"; chmod 555 "$r/data/locked"
  t="$SANDBOX/rmfail-target"
  out="$(link "$r" "$t" 2>"$SANDBOX/rmfail.err")"; rc=$?
  check "rm fails: exit 0" test "$rc" = 0
  check "rm fails: data linked to target" test -L "$r/data" -a "$(readlink "$r/data")" = "$t"
  check "rm fails: all files at target" test "$(find "$t" -type f | wc -l | tr -d ' ')" = 3
  check "rm fails: config recorded" test "$(git -C "$r" config --local --get iago.dataDir)" = "$t"
  check "rm fails: warning names leftover" grep -q "data.iago-moved" "$SANDBOX/rmfail.err"
  check "rm fails: leftover= key" grep -q "^leftover=.*data.iago-moved" <<< "$out"
  check "rm fails: leftover ignored by git" test -z "$(cd "$r" && git status --porcelain)"
  chmod -R u+rwX "$r"/data.iago-moved.* 2>/dev/null
fi
echo "move: renaming data/ aside fails"
r="$(new_repo renamefail)"; seed "$r/data"; t="$SANDBOX/renamefail-target"
shim "$SANDBOX/shim-mv" mv 'case "$1" in */data) exit 1 ;; esac; exec "$REAL" "$@"'
err="$(PATH="$SANDBOX/shim-mv:$PATH" bash "$r/scripts/link-data.sh" "$t" 2>&1 >/dev/null)"; rc=$?
check "rename fails: exit 1" test "$rc" = 1
check "rename fails: data still a real dir" test -d "$r/data" -a ! -L "$r/data"
check "rename fails: all files still in data/" test "$(find "$r/data" -type f | wc -l | tr -d ' ')" = 2
check "rename fails: no config recorded" test -z "$(git -C "$r" config --local --get iago.dataDir)"
check "rename fails: error names the copy" grep -q "renamefail-target" <<< "$err"
echo "move: relative symlink that would dangle after the move"
r="$(new_repo relink)"; seed "$r/data"; ln -s ../examples/config.example.yaml "$r/data/rel.yaml"; ln -s /nonexistent-iago "$r/data/dead"
t="$SANDBOX/relink-target"
err="$(link "$r" "$t" 2>&1 >/dev/null)"; rc=$?
check "rel link: exit 1" test "$rc" = 1
check "rel link: data still a real dir" test -d "$r/data" -a ! -L "$r/data"
check "rel link: link intact in data/" test -f "$r/data/rel.yaml"
check "rel link: error names the link" grep -q "rel.yaml" <<< "$err"
check "rel link: target not created" test ! -e "$t"
r="$(new_repo deadlink)"; seed "$r/data"; ln -s /nonexistent-iago "$r/data/dead"
link "$r" "$SANDBOX/deadlink-target" >/dev/null 2>&1; rc=$?
check "already-dangling link: move ok" test "$rc" = 0 -a -L "$SANDBOX/deadlink-target/dead"
echo "move: target with only placeholders and empty subfolders"
r="$(new_repo phtarget)"; seed "$r/data"; t="$SANDBOX/phtarget-t"
mkdir -p "$t/a/b" "$t/c"; touch "$t/.gitkeep" "$t/a/.DS_Store" "$t/c/.gitkeep"
out="$(link "$r" "$t" 2>/dev/null)"; rc=$?
check "placeholders: action=move" test "$(echo "$out" | field action)" = move
check "placeholders: exit 0" test "$rc" = 0
check "placeholders: linked" test -L "$r/data"
check "placeholders: files present" test -f "$t/daily-runs/2026-01-01.md"
echo "noop: fixes a mismatched configured folder"
r="$(new_repo noopcfg)"; a="$SANDBOX/noopcfg-a"; link "$r" "$a" >/dev/null
git -C "$r" config --local iago.dataDir "$SANDBOX/noopcfg-elsewhere"
out="$(link "$r" "$a" 2>/dev/null)"
check "noop mismatch: action=noop" test "$(echo "$out" | field action)" = noop
check "noop mismatch: config updated" test "$(cfg "$r")" = "$a"
check "noop mismatch: status linked" test "$(link "$r" --status 2>/dev/null | field mode)" = linked
echo "Iago copy without its own .git inside another git repo"
mono="$SANDBOX/mono"; mkdir -p "$mono"; git -C "$mono" init -q
mkdir "$mono/Iago"; cp -R "$SRC_ROOT/scripts" "$SRC_ROOT/examples" "$SRC_ROOT/.gitignore" "$mono/Iago/"; seed "$mono/Iago/data"
link "$mono/Iago" "$SANDBOX/mono-target" >/dev/null 2>&1; rc=$?
check "enclosing repo: link exit 0" test "$rc" = 0
check "enclosing repo: parent config untouched" test -z "$(git -C "$mono" config --local --get iago.dataDir)"
git -C "$mono" config --local iago.dataDir "$SANDBOX/mono-other"
mkdir -p "$mono/Iago2"; cp -R "$SRC_ROOT/scripts" "$SRC_ROOT/examples" "$mono/Iago2/"; mkdir "$mono/Iago2/data"
check "enclosing repo: status ignores parent config" test "$(link "$mono/Iago2" --status 2>/dev/null | field mode)" = in-repo
bash "$mono/Iago2/scripts/init-data.sh" </dev/null >/dev/null 2>&1; rc=$?
check "enclosing repo: guard ignores parent config" test "$rc" = 0
# --- end sections ---
echo
echo "passed=$pass failed=$fail"
[[ "$fail" == 0 ]]
