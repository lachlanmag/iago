#!/usr/bin/env bash
# Local daily job search via Pi + LM Studio (no Cursor cloud).
# Prerequisites: LM Studio server running, pi installed, bash scripts/install-pi-skills.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$REPO_ROOT/data"
LOG_DIR="$DATA_DIR/logs"
mkdir -p "$LOG_DIR" "$DATA_DIR/daily-runs"

if [[ ! -f "$DATA_DIR/config.yaml" ]]; then
  echo "Missing data/config.yaml: run: bash scripts/init-data.sh" >&2
  exit 1
fi

if ! command -v pi >/dev/null 2>&1; then
  echo "pi not found. Install: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
fi

IAGO_TZ="${IAGO_TZ:-Australia/Brisbane}"
PI_PROVIDER="${PI_PROVIDER:-lmstudio}"
PI_MODEL="${PI_MODEL:-qwen/qwen3.5-9b}"

local_date() {
  TZ="$IAGO_TZ" date "$@"
}

TIMESTAMP="$(local_date +%Y-%m-%d_%H-%M-%S)"
RUN_DATE="$(local_date +%Y-%m-%d)"
LOG_FILE="$LOG_DIR/daily-pi-${TIMESTAMP}.log"

PROMPT="$(cat <<EOF
/skill:iago-daily

Run date (${IAGO_TZ}): ${RUN_DATE}
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

Notes for local Pi runs:
- REPO_ROOT is this directory: ${REPO_ROOT}
- Use bash and curl for web fetches; use pi-skills web search if installed
- Write files under data/ only; never commit personal data
EOF
)"

{
  echo "=== Daily job search (Pi + LM Studio) started: $(local_date -Iseconds) (${IAGO_TZ}, run date ${RUN_DATE}) ==="
  echo "Repo: $REPO_ROOT"
  echo "Provider: $PI_PROVIDER"
  echo "Model: $PI_MODEL"
  echo

  cd "$REPO_ROOT"

  pi -p \
    --approve \
    --no-session \
    --provider "$PI_PROVIDER" \
    --model "$PI_MODEL" \
    --skill "$REPO_ROOT/.cursor/skills/iago-daily" \
    "$PROMPT"

  EXIT=$?

  echo
  echo "=== Finished: $(local_date -Iseconds) (${IAGO_TZ}, run date ${RUN_DATE}) (exit $EXIT) ==="
  exit "$EXIT"
} >>"$LOG_FILE" 2>&1

ln -sf "$LOG_FILE" "$LOG_DIR/latest-pi.log"
