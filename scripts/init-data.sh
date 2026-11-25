#!/usr/bin/env bash
# Copy example templates into data/ for first-time setup.
# Safe to re-run: skips files that already exist.
#
# Usage:
#   bash scripts/init-data.sh                     # asks where to store data if data/ is missing
#   bash scripts/init-data.sh --data-dir <folder> # store data outside the repo (see link-data.sh)
#   bash scripts/init-data.sh --keep-in-repo      # plain gitignored data/ inside the repo

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLES="$REPO_ROOT/examples"
DATA="$REPO_ROOT/data"

# shellcheck source=lib/data-dir.sh
source "$REPO_ROOT/scripts/lib/data-dir.sh"

data_dir=""
keep_in_repo=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --data-dir)
      data_dir="${2:-}"
      [[ -n "$data_dir" ]] || { echo "error: --data-dir requires a folder" >&2; exit 1; }
      shift 2 ;;
    --keep-in-repo) keep_in_repo=true; shift ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$data_dir" && "$keep_in_repo" == true ]]; then
  echo "error: use either --data-dir or --keep-in-repo, not both" >&2
  exit 1
fi

iago_require_data_dir "$REPO_ROOT" || exit $?

if [[ -n "$data_dir" ]]; then
  bash "$REPO_ROOT/scripts/link-data.sh" "$data_dir"
elif [[ ! -e "$DATA" && "$keep_in_repo" != true && -t 0 ]]; then
  echo "Where should Iago store your job search data?"
  echo "  Pick a folder your sync tool (Nextcloud, Google Drive, Syncthing...) syncs to use Iago on several computers."
  read -r -p "Folder path (blank = keep inside this repo): " data_dir
  if [[ -n "$data_dir" ]]; then
    bash "$REPO_ROOT/scripts/link-data.sh" "$data_dir"
  fi
fi

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
