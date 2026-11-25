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
# Exit: 0 ok, 1 error, 2 conflict, 3 refused (inside/contains repo), 4 broken/unlinked.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
DATA="$REPO_ROOT/data"
# shellcheck source=lib/data-dir.sh
source "$REPO_ROOT/scripts/lib/data-dir.sh"

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
}

# Expand ~ and relative paths. Existing directories are resolved physically
# (symlinks, case on case-insensitive filesystems); the non-existing tail is
# normalised lexically ('.', '..', repeated and trailing slashes).
abspath() {
  local p="$1" base="/" tail="" seg nb
  local -a parts
  case "$p" in
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
    /*) ;;
    *) p="$PWD/$p" ;;
  esac
  IFS=/ read -r -a parts <<< "$p"
  for seg in ${parts[@]+"${parts[@]}"}; do
    case "$seg" in
      ""|.) ;;
      ..)
        if [[ -n "$tail" ]]; then
          tail="${tail%/*}"
        else
          base="$(cd -P -- "${base%/}/.." 2>/dev/null && pwd -P)" || base="/"
        fi ;;
      *)
        if [[ -z "$tail" && -d "${base%/}/$seg" ]] && nb="$(cd -P -- "${base%/}/$seg" 2>/dev/null && pwd -P)"; then
          base="$nb"
        else
          tail="$tail/$seg"
        fi ;;
    esac
  done
  if [[ "$base" == / ]]; then
    echo "${tail:-/}"
  else
    echo "$base$tail"
  fi
}

# True when $1 is inside the repo, is the repo, or contains the repo.
# Compares inodes (-ef), so case variants and symlinked paths are caught.
overlaps_repo() {
  local t="$1" d
  [[ "$t" == "$REPO_ROOT" || "$t" == "$REPO_ROOT"/* ]] && return 0
  d="$t"
  while :; do
    [[ -e "$d" && "$d" -ef "$REPO_ROOT" ]] && return 0
    [[ "$d" == / || -z "$d" ]] && break
    d="$(dirname "$d")"
  done
  if [[ -e "$t" ]]; then
    d="$REPO_ROOT"
    while :; do
      [[ "$d" -ef "$t" ]] && return 0
      [[ "$d" == / || -z "$d" ]] && break
      d="$(dirname "$d")"
    done
  fi
  return 1
}

refuse_msg() {
  echo "error: $(tilde "$1") is inside the Iago repo or contains it; choose a folder outside $(tilde "$REPO_ROOT")" >&2
}

# Re-check after creating directories, right before copying or deleting.
require_outside_repo() {
  if overlaps_repo "$1"; then
    refuse_msg "$1"
    exit 3
  fi
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

# Physical state of data/ (ignores the configured folder); used for planning.
data_mode() {
  iago_data_mode "$REPO_ROOT" ""
}

# Remember this machine's folder so a git checkout that drops the symlink is
# detected later. Skipped silently when git or the repo is unavailable.
record_configured() {
  command -v git >/dev/null 2>&1 || return 0
  git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1 || return 0
  git -C "$REPO_ROOT" config --local iago.dataDir "$1" 2>/dev/null || true
}

cmd_status() {
  local mode physical conf
  conf="$(iago_configured_dir "$REPO_ROOT")"
  mode="$(iago_data_mode "$REPO_ROOT" "$conf")"
  physical="$(data_mode)"
  echo "mode=$mode"
  echo "repo=$(tilde "$REPO_ROOT")"
  echo "configured=${conf:+$(tilde "$conf")}"
  case "$physical" in
    linked|broken) echo "target=$(tilde "$(readlink "$DATA")")" ;;
    in-repo|other) echo "target=$(tilde "$DATA")" ;;
    *) echo "target=" ;;
  esac
  echo "files=$(count_files "$DATA")"
  echo "kb=$(kb_of "$DATA")"
  case "$mode" in
    broken|unlinked)
      echo "hint=$(iago_data_hint "$mode" "$REPO_ROOT" "$conf")" >&2
      return 4 ;;
  esac
}

# Decide what linking to $1 would do. Prints action; never changes anything.
plan_action() {
  local target="$1" mode local_n target_n
  if overlaps_repo "$target"; then
    echo refuse; return
  fi
  mode="$(data_mode)"
  local_n="$(count_files "$DATA")"
  target_n="$(count_files "$target")"
  case "$mode" in
    linked|broken)
      if [[ "$(readlink "$DATA")" == "$target" ]] || [[ -e "$target" && "$DATA" -ef "$target" ]]; then
        echo noop
      else
        echo repoint
      fi ;;
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
  # Never count a refused target: it may be a huge parent folder (or /).
  [[ "$action" == refuse ]] && return 0
  echo "local_files=$(count_files "$DATA")"
  echo "local_kb=$(kb_of "$DATA")"
  echo "target_files=$(count_files "$target")"
  echo "target_kb=$(kb_of "$target")"
}

make_link() {
  ln -sfn "$1" "$DATA"
}

move_fail() {
  echo "error: $1; data/ left in place, nothing removed." >&2
  [[ -n "${2:-}" && -e "$2" ]] && echo "  Partial copy kept at $(tilde "$2") (safe to delete)." >&2
  return 1
}

# Copy data/ into a staging folder next to the target, verify it, move the
# staging folder into place, and only then remove the in-repo data/.
move_data() {
  local target="$1" parent staging before after
  parent="$(dirname "$target")"
  staging="$parent/$(basename "$target").iago-partial.$$"
  mkdir -p "$parent" || { move_fail "could not create $(tilde "$parent")"; return 1; }
  require_outside_repo "$target"
  require_outside_repo "$staging"
  mkdir "$staging" || { move_fail "could not create $(tilde "$staging")"; return 1; }
  before="$(count_files "$DATA")"
  if ! cp -Rp "$DATA/." "$staging/"; then
    move_fail "copy failed" "$staging"; return 1
  fi
  if ! diff -rq "$DATA" "$staging" >/dev/null 2>&1; then
    move_fail "copy verification failed (contents differ)" "$staging"; return 1
  fi
  after="$(count_files "$staging")"
  if [[ "$after" != "$before" ]]; then
    move_fail "copy verification failed ($before files in data/, $after copied)" "$staging"; return 1
  fi
  if [[ -d "$target" && ! -L "$target" ]]; then
    rm -f "$target/.DS_Store"
    rmdir "$target" 2>/dev/null || { move_fail "$(tilde "$target") is not empty" "$staging"; return 1; }
  elif [[ -e "$target" || -L "$target" ]]; then
    move_fail "$(tilde "$target") exists and is not a folder" "$staging"; return 1
  fi
  mv "$staging" "$target" || { move_fail "could not move $(tilde "$staging") to $(tilde "$target")" "$staging"; return 1; }
  rm -rf "$DATA"
}

cmd_apply() {
  local target="$1" dry="$2" force="$3" action
  action="$(plan_action "$target")"
  print_plan "$action" "$target"

  case "$action" in
    refuse)
      refuse_msg "$target"
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
    noop)
      [[ -n "$(iago_configured_dir "$REPO_ROOT")" ]] || record_configured "$target" ;;
    create|link)
      mkdir -p "$target"
      require_outside_repo "$target"
      # In-repo data/ has no real files here (only placeholders): safe to replace.
      [[ -d "$DATA" && ! -L "$DATA" ]] && rm -rf "$DATA"
      make_link "$target" ;;
    move)
      move_data "$target" || return 1
      make_link "$target" ;;
    repoint)
      mkdir -p "$target"
      require_outside_repo "$target"
      rm "$DATA"
      make_link "$target" ;;
    conflict)
      require_outside_repo "$target"
      local backup
      backup="$DATA.local-backup-$(date +%Y%m%d-%H%M%S)"
      mv "$DATA" "$backup"
      echo "backup=$(tilde "$backup")"
      make_link "$target" ;;
  esac
  [[ "$action" == noop ]] || record_configured "$target"
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
