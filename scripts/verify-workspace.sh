#!/usr/bin/env bash
# Check that Iago skills are reachable from the Cursor, Claude Code, or LM Studio workspace.
# Exit 0: workspace root matches repo root (project skills auto-discover).
# Exit 2: repo ok but workspace root differs (run install-skills.sh or re-open folder).
# Exit 1: skills missing at repo root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
platform="both"
WORKSPACE_ROOT=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--platform cursor|claude|lmstudio|both] [workspace-root]

Verify Iago skill layout at repo root and workspace layout.

Platforms:
  both      Check .cursor/, .claude/, and .lmstudio/ (default: any one present)
  cursor    Check .cursor/skills/iago-setup/SKILL.md only
  claude    Check .claude/skills/iago-setup/SKILL.md only
  lmstudio  Check .lmstudio/skills/iago-setup/SKILL.md only
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      if [[ $# -lt 2 ]]; then
        echo "error: --platform requires an argument" >&2
        usage >&2
        exit 1
      fi
      platform="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$WORKSPACE_ROOT" ]]; then
        echo "error: unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      WORKSPACE_ROOT="$1"
      shift
      ;;
  esac
done

if [[ -z "$WORKSPACE_ROOT" ]]; then
  WORKSPACE_ROOT="${CURSOR_WORKSPACE:-$(pwd)}"
fi

# Resolve to absolute paths when possible
if command -v realpath >/dev/null 2>&1; then
  REPO_ROOT="$(realpath "$REPO_ROOT")"
  WORKSPACE_ROOT="$(realpath "$WORKSPACE_ROOT" 2>/dev/null || echo "$WORKSPACE_ROOT")"
fi

echo "repo_root=$REPO_ROOT"
echo "workspace_root=$WORKSPACE_ROOT"

cursor_skill="$REPO_ROOT/.cursor/skills/iago-setup/SKILL.md"
claude_skill="$REPO_ROOT/.claude/skills/iago-setup/SKILL.md"
lmstudio_skill="$REPO_ROOT/.lmstudio/skills/iago-setup/SKILL.md"

skills_ok=false
case "$platform" in
  cursor)
    [[ -f "$cursor_skill" ]] && skills_ok=true
    ;;
  claude)
    [[ -f "$claude_skill" ]] && skills_ok=true
    ;;
  lmstudio)
    [[ -f "$lmstudio_skill" ]] && skills_ok=true
    ;;
  both)
    [[ -f "$cursor_skill" || -f "$claude_skill" || -f "$lmstudio_skill" ]] && skills_ok=true
    ;;
  *)
    echo "error: invalid platform: $platform (expected cursor, claude, lmstudio, or both)" >&2
    usage >&2
    exit 1
    ;;
esac

if [[ "$skills_ok" != true ]]; then
  echo "skills_at_repo_root=no"
  echo "hint=Corrupt or partial checkout; re-clone Iago." >&2
  exit 1
fi

echo "skills_at_repo_root=yes"

if [[ "$WORKSPACE_ROOT" == "$REPO_ROOT" ]]; then
  echo "workspace_matches_repo=yes"
  exit 0
fi

open_hint="Open $REPO_ROOT as the workspace root (Cursor, Claude Code, or LM Studio chat)"
cursor_claude_hint="Cursor/Claude parent workspace: bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform both"
lmstudio_hint="LM Studio: open chat with workspace=$REPO_ROOT (install-skills --platform lmstudio only prints the Skills Directory path; it does not fix a wrong workspace)"

# Workspace is a parent or sibling: nested/monorepo layout
if [[ "$REPO_ROOT" == "$WORKSPACE_ROOT"/* ]]; then
  echo "workspace_matches_repo=no"
  echo "layout=nested"
  echo "hint=$open_hint. $cursor_claude_hint. $lmstudio_hint"
  exit 2
fi

echo "workspace_matches_repo=no"
echo "layout=external"
echo "hint=$open_hint. $cursor_claude_hint. $lmstudio_hint"
exit 2
