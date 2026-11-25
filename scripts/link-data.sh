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
