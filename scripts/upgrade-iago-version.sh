#!/usr/bin/env bash
# Upgrade Iago to the latest version from GitHub: pull, merge new config keys, refresh global skill symlinks when needed.
# Existing data/config.yaml values are never overwritten. See README "Upgrading Iago".
#
# Usage:
#   bash scripts/upgrade-iago-version.sh           # pull + reconcile + install-skills if nested workspace
#   bash scripts/upgrade-iago-version.sh --check   # fetch and report whether a newer version is available
#   bash scripts/upgrade-iago-version.sh --dry-run # reconcile-config preview only (no pull)
#
# Optional env:
#   CURSOR_WORKSPACE=/path/to/cursor/root  # used to detect nested layout (install-skills)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE=apply

for arg in "$@"; do
  case "$arg" in
    --dry-run) MODE=dry-run ;;
    --check) MODE=check ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not a git repository: $REPO_ROOT" >&2
  exit 1
fi

fetch_ok=1
if ! git -C "$REPO_ROOT" fetch origin; then
  fetch_ok=0
  echo "warn: git fetch failed; using local refs only" >&2
fi

if [[ "$fetch_ok" -eq 0 && "$MODE" != "dry-run" ]]; then
  echo "error: cannot check or upgrade version without network access to origin" >&2
  exit 1
fi

current_branch="$(git -C "$REPO_ROOT" branch --show-current)"
if [[ -z "$current_branch" ]]; then
  echo "error: detached HEAD; checkout a branch before upgrading" >&2
  exit 1
fi

upstream="origin/${current_branch}"
if ! git -C "$REPO_ROOT" rev-parse --verify "$upstream" >/dev/null 2>&1; then
  upstream="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
fi

behind=0
ahead=0
if [[ -n "$upstream" ]] && git -C "$REPO_ROOT" rev-parse --verify "$upstream" >/dev/null 2>&1; then
  behind="$(git -C "$REPO_ROOT" rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)"
  ahead="$(git -C "$REPO_ROOT" rev-list --count "$upstream..HEAD" 2>/dev/null || echo 0)"
fi

echo "repo_root=$REPO_ROOT"
echo "branch=$current_branch"
echo "behind_origin=$behind"
echo "ahead_origin=$ahead"

if [[ "$MODE" == "check" ]]; then
  if [[ "$behind" -gt 0 ]]; then
    echo "status=version_upgrade_available"
    git -C "$REPO_ROOT" log --oneline "HEAD..$upstream" | head -10
    exit 0
  fi
  echo "status=up_to_date"
  exit 0
fi

if [[ "$MODE" == "apply" ]]; then
  if ! git -C "$REPO_ROOT" diff --quiet || ! git -C "$REPO_ROOT" diff --cached --quiet; then
    echo "error: uncommitted changes in tracked files; commit or stash before upgrading" >&2
    git -C "$REPO_ROOT" status --short >&2
    exit 1
  fi

  if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
    echo "error: branch is ahead and behind origin; resolve manually before upgrading" >&2
    exit 1
  fi

  if [[ "$behind" -gt 0 ]]; then
    git -C "$REPO_ROOT" pull --ff-only origin "$current_branch"
    echo "pull=done"
  else
    echo "pull=skipped (already up to date)"
  fi
fi

reconcile_args=()
if [[ "$MODE" == "dry-run" ]]; then
  reconcile_args=(--dry-run)
fi

if ! python3 -c "import ruamel.yaml" 2>/dev/null; then
  echo "error: ruamel.yaml not installed (needed for config merge)" >&2
  echo "hint: pip3 install ruamel.yaml" >&2
  exit 2
fi

bash "$REPO_ROOT/scripts/reconcile-config.sh" "${reconcile_args[@]}"

if [[ "$MODE" != "dry-run" ]]; then
  workspace="${CURSOR_WORKSPACE:-$REPO_ROOT}"
  ws_exit=0
  bash "$REPO_ROOT/scripts/verify-workspace.sh" "$workspace" || ws_exit=$?

  if [[ $ws_exit -eq 2 ]]; then
    echo "install_skills=nested_workspace"
    bash "$REPO_ROOT/scripts/install-skills.sh"
  elif [[ $ws_exit -eq 0 ]]; then
    echo "install_skills=not_needed"
  else
    echo "install_skills=skipped (verify exit $ws_exit)" >&2
  fi
fi

echo "head=$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
if [[ "$MODE" == "dry-run" ]]; then
  echo "done: config preview only (no pull, no skill install)"
else
  echo "done: Iago version upgraded (data/ untouched except new config keys)"
  echo "reload_cursor: Cmd+Shift+P → Developer: Reload Window"
fi
