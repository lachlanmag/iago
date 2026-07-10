#!/usr/bin/env bash
# Copy example templates into data/ for first-time setup.
# Safe to re-run: skips files that already exist.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLES="$REPO_ROOT/examples"
DATA="$REPO_ROOT/data"

mkdir -p "$DATA/daily-runs" "$DATA/pipeline-reviews" "$DATA/jds" "$DATA/company-research" "$DATA/interview-prep" "$DATA/resume-feedback" "$DATA/logs"

copy_if_missing() {
  local src="$1"
  local dest="$2"
  if [[ -f "$dest" ]]; then
    echo "skip (exists): $dest"
  else
    cp "$src" "$dest"
    echo "created: $dest"
  fi
}

copy_if_missing "$EXAMPLES/config.example.yaml" "$DATA/config.yaml"
copy_if_missing "$EXAMPLES/applications.example.yaml" "$DATA/applications.yaml"
copy_if_missing "$EXAMPLES/seen-jobs.example.yaml" "$DATA/seen-jobs.yaml"
copy_if_missing "$EXAMPLES/recruiters.example.yaml" "$DATA/recruiters.yaml"

echo
echo "Installing skills (safe to re-run)..."
if ! bash "$REPO_ROOT/scripts/install-skills.sh" --platform both; then
  echo "warning: skill install failed (data/ templates were still created)" >&2
  echo "  Retry: bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform both" >&2
fi

echo
echo "Next steps:"
echo "  1. Pick a platform and run setup in chat: Set up job search  (or edit data/config.yaml manually)"
echo "     - Cursor: open repo root, then /iago-setup"
echo "     - Claude Code: open repo root (or install-skills.sh --platform claude), then /iago-setup"
echo "     - LM Studio: bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform lmstudio"
echo "       then follow docs/lm-studio-setup.md and run /iago-setup in chat"
echo "  2. Parent/monorepo workspace (Cursor/Claude): bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform both"
echo "  3. Keep running daily search from chat, or schedule via your platform's runner docs"
