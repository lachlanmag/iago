#!/usr/bin/env bash
# Local daily job search: runs Cursor Agent CLI against this repo (no cloud).
# Prerequisites: cursor agent login (once), Cursor installed, network for job search.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$REPO_ROOT/data"
LOG_DIR="$DATA_DIR/logs"
mkdir -p "$LOG_DIR" "$DATA_DIR/daily-runs"

if [[ ! -f "$DATA_DIR/config.yaml" ]]; then
  echo "Missing data/config.yaml: run: bash scripts/init-data.sh" >&2
  exit 1
fi

# Default timezone for run date. Override with JOB_SEARCH_TZ if needed.
JOB_SEARCH_TZ="${JOB_SEARCH_TZ:-Australia/Brisbane}"

local_date() {
  TZ="$JOB_SEARCH_TZ" date "$@"
}

TIMESTAMP="$(local_date +%Y-%m-%d_%H-%M-%S)"
RUN_DATE="$(local_date +%Y-%m-%d)"
LOG_FILE="$LOG_DIR/daily-${TIMESTAMP}.log"

resolve_cursor() {
  if [[ -n "${CURSOR_CLI_PATH:-}" && -x "${CURSOR_CLI_PATH}" ]]; then
    echo "${CURSOR_CLI_PATH}"
    return
  fi
  if command -v cursor >/dev/null 2>&1; then
    command -v cursor
    return
  fi
  local mac_default="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
  if [[ -x "$mac_default" ]]; then
    echo "$mac_default"
    return
  fi
  echo "Cursor CLI not found. Install Cursor or set CURSOR_CLI_PATH." >&2
  exit 1
}

CURSOR="$(resolve_cursor)"

PROMPT="$(cat <<EOF
Read and follow the job-search-daily skill at .cursor/skills/job-search-daily/SKILL.md in this workspace.

Run date (${JOB_SEARCH_TZ}): ${RUN_DATE}
Use this date for the daily report filename, discovered/applied fields, listing_verified, closing-date comparisons, and listing_freshness checks: not the system UTC date.

Run the full daily workflow:
1. Load data/config.yaml, data/applications.yaml, data/seen-jobs.yaml, and profile.resume_path from config
2. Search all sources in config search_sources.order (skip excluded_sources)
3. For EVERY candidate during search: apply listing_freshness at intake: skip expired roles immediately
4. Dedup every intake-passing candidate per config deduplication rules: canonical URL only
5. Score and tier intake-passing candidates (industry ★/⚠, resume_fit ✓/~)
6. Run mandatory QA gate (config qa_gate) BEFORE any tracker write
7. Write data/daily-runs/${RUN_DATE}.md (include Skipped expired, Closing soon, QA gate, Deduped sections)
8. Append ONLY QA-passing new roles to data/applications.yaml and data/seen-jobs.yaml

End with top 3 apply-today picks: each must have passed QA verify_listing_open.
EOF
)"

{
  echo "=== Daily job search started: $(local_date -Iseconds) (${JOB_SEARCH_TZ}, run date ${RUN_DATE}) ==="
  echo "Repo: $REPO_ROOT"
  echo "Cursor: $CURSOR"
  echo

  cd "$REPO_ROOT"

  CMD=(
    "$CURSOR" agent -p
    --trust
    --force
    --workspace "$REPO_ROOT"
  )

  if [[ -n "${CURSOR_AGENT_MODEL:-}" ]]; then
    CMD+=(--model "$CURSOR_AGENT_MODEL")
  fi

  CMD+=("$PROMPT")

  "${CMD[@]}"
  EXIT=$?

  echo
  echo "=== Finished: $(local_date -Iseconds) (${JOB_SEARCH_TZ}, run date ${RUN_DATE}) (exit $EXIT) ==="
  exit "$EXIT"
} >>"$LOG_FILE" 2>&1

ln -sf "$LOG_FILE" "$LOG_DIR/latest.log"
