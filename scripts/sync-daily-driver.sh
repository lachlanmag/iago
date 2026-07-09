#!/usr/bin/env bash
# Refresh a separate daily-driver Iago checkout after merging to main.
# Optional solo-maintainer layout: dev clone (feature branches) + daily driver on
# main (real data/). Everyone else: git pull in one folder; see README "Updating Iago".
#
# Usage (from your dev clone):
#   bash scripts/sync-daily-driver.sh           # pull main into daily driver + reconcile config
#   bash scripts/sync-daily-driver.sh --dry-run # preview config keys to add
#
# Set daily-driver path when auto-detect cannot find a second worktree on main:
#   IAGO_DAILY_DRIVER_ROOT=/path/to/daily-driver bash scripts/sync-daily-driver.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,13p' "$0"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

resolve_daily_driver_root() {
  local repo_root="$1"
  local wt_path="" wt_branch=""
  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        wt_path="${line#worktree }"
        wt_branch=""
        ;;
      branch\ *)
        wt_branch="${line#branch refs/heads/}"
        if [[ "$wt_branch" == "main" && "$wt_path" != "$repo_root" ]]; then
          printf '%s' "$wt_path"
          return 0
        fi
        ;;
    esac
  done < <(git -C "$repo_root" worktree list --porcelain)
  return 1
}

if [[ -n "${IAGO_DAILY_DRIVER_ROOT:-}" ]]; then
  DAILY_DRIVER_ROOT="$IAGO_DAILY_DRIVER_ROOT"
else
  if ! DAILY_DRIVER_ROOT="$(resolve_daily_driver_root "$REPO_ROOT")"; then
    echo "error: could not find a daily-driver worktree (second checkout on main)." >&2
    echo "hint: git -C \"$REPO_ROOT\" worktree list" >&2
    echo "hint: set IAGO_DAILY_DRIVER_ROOT=/path/to/daily-driver bash scripts/sync-daily-driver.sh" >&2
    exit 1
  fi
fi

if ! git -C "$REPO_ROOT" worktree list --porcelain | grep -qFx "worktree $DAILY_DRIVER_ROOT"; then
  echo "error: daily-driver worktree not found at $DAILY_DRIVER_ROOT" >&2
  echo "hint: git -C \"$REPO_ROOT\" worktree list" >&2
  exit 1
fi

echo "dev_clone=$REPO_ROOT"
echo "daily_driver=$DAILY_DRIVER_ROOT"

git -C "$REPO_ROOT" fetch origin

current_branch="$(git -C "$DAILY_DRIVER_ROOT" branch --show-current 2>/dev/null || true)"
if [[ "$current_branch" != "main" ]]; then
  git -C "$DAILY_DRIVER_ROOT" checkout main
fi

git -C "$DAILY_DRIVER_ROOT" pull --ff-only origin main

if [[ "$DRY_RUN" -eq 1 ]]; then
  bash "$DAILY_DRIVER_ROOT/scripts/reconcile-config.sh" --dry-run
else
  bash "$DAILY_DRIVER_ROOT/scripts/reconcile-config.sh"
  bash "$DAILY_DRIVER_ROOT/scripts/install-skills.sh"
fi

echo "daily_driver_head=$(git -C "$DAILY_DRIVER_ROOT" rev-parse --short HEAD)"
echo "done: daily-driver checkout updated (data/ untouched)"
echo "reload Cursor after skill changes: Cmd+Shift+P → Developer: Reload Window"
