#!/usr/bin/env bash
# Update a separate prod Iago worktree from main after merging improvements.
# For contributors who keep daily job-search data in one checkout (prod) and
# develop skills/scripts in another (dev). Typical single-folder users should
# use git pull instead; see README "Updating Iago".
#
# Usage (from your primary dev clone):
#   bash scripts/sync-prod.sh           # pull main into prod + reconcile config
#   bash scripts/sync-prod.sh --dry-run # preview config keys to add
#
# Set prod path explicitly when auto-detect cannot find a second worktree on main:
#   IAGO_PROD_ROOT=/path/to/prod bash scripts/sync-prod.sh

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

resolve_prod_root() {
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

if [[ -n "${IAGO_PROD_ROOT:-}" ]]; then
  PROD_ROOT="$IAGO_PROD_ROOT"
else
  if ! PROD_ROOT="$(resolve_prod_root "$REPO_ROOT")"; then
    echo "error: could not find a prod worktree (second checkout on main)." >&2
    echo "hint: git -C \"$REPO_ROOT\" worktree list" >&2
    echo "hint: set IAGO_PROD_ROOT=/path/to/prod bash scripts/sync-prod.sh" >&2
    exit 1
  fi
fi

if ! git -C "$REPO_ROOT" worktree list --porcelain | grep -qFx "worktree $PROD_ROOT"; then
  echo "error: prod worktree not found at $PROD_ROOT" >&2
  echo "hint: git -C \"$REPO_ROOT\" worktree list" >&2
  exit 1
fi

echo "dev_clone=$REPO_ROOT"
echo "prod_worktree=$PROD_ROOT"

git -C "$REPO_ROOT" fetch origin

current_branch="$(git -C "$PROD_ROOT" branch --show-current 2>/dev/null || true)"
if [[ "$current_branch" != "main" ]]; then
  git -C "$PROD_ROOT" checkout main
fi

git -C "$PROD_ROOT" pull --ff-only origin main

if [[ "$DRY_RUN" -eq 1 ]]; then
  bash "$PROD_ROOT/scripts/reconcile-config.sh" --dry-run
else
  bash "$PROD_ROOT/scripts/reconcile-config.sh"
  bash "$PROD_ROOT/scripts/install-skills.sh"
fi

echo "prod_head=$(git -C "$PROD_ROOT" rev-parse --short HEAD)"
echo "done: prod worktree updated (data/ untouched)"
echo "reload Cursor after skill changes: Cmd+Shift+P → Developer: Reload Window"
