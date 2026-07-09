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
echo "  1. In Cursor or Claude Code: Set up job search  (or edit data/config.yaml manually)"
echo "     If skills are missing: bash \"$REPO_ROOT/scripts/verify-workspace.sh\""
echo "     Monorepo/parent workspace: bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform both"
echo "     (after version upgrades: run iago-upgrade-version in chat or bash \"$REPO_ROOT/scripts/upgrade-iago-version.sh\")"
echo "     (after config schema upgrades: bash \"$REPO_ROOT/scripts/reconcile-config.sh\" to add new example keys)"
echo "  2. Run: Run the daily job search"
echo "  3. After shortlisting: company-research runs automatically (or /company-research)"
echo "  4. Before applying: /resume-feedback, then set applied via update-application"
echo "     (default: markdown from profile.resume_path; matcher on: tailor via Resume-Matcher, provide JSON)"
