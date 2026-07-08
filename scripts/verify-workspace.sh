#!/usr/bin/env bash
# Check that Iago skills are reachable from the Cursor workspace.
# Exit 0: workspace root matches repo root (project skills auto-discover).
# Exit 2: repo ok but workspace root differs (run install-skills.sh or re-open folder).
# Exit 1: skills missing at repo root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_ROOT="${1:-${CURSOR_WORKSPACE:-$(pwd)}}"

# Resolve to absolute paths when possible
if command -v realpath >/dev/null 2>&1; then
  REPO_ROOT="$(realpath "$REPO_ROOT")"
  WORKSPACE_ROOT="$(realpath "$WORKSPACE_ROOT" 2>/dev/null || echo "$WORKSPACE_ROOT")"
fi

echo "repo_root=$REPO_ROOT"
echo "workspace_root=$WORKSPACE_ROOT"

if [[ ! -f "$REPO_ROOT/.cursor/skills/iago-setup/SKILL.md" ]]; then
  echo "skills_at_repo_root=no"
  echo "hint=Corrupt or partial checkout; re-clone Iago." >&2
  exit 1
fi

echo "skills_at_repo_root=yes"

if [[ "$WORKSPACE_ROOT" == "$REPO_ROOT" ]]; then
  echo "workspace_matches_repo=yes"
  exit 0
fi

# Workspace is a parent or sibling: nested/monorepo layout
if [[ "$REPO_ROOT" == "$WORKSPACE_ROOT"/* ]]; then
  echo "workspace_matches_repo=no"
  echo "layout=nested"
  echo "hint=Open $REPO_ROOT in Cursor (File → Open Folder), or run: bash \"$REPO_ROOT/scripts/install-skills.sh\""
  exit 2
fi

echo "workspace_matches_repo=no"
echo "layout=external"
echo "hint=Open $REPO_ROOT in Cursor, or run: bash \"$REPO_ROOT/scripts/install-skills.sh\""
exit 2
