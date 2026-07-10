#!/usr/bin/env bash
# Sanity-check LM Studio + Pi + Iago skills before a local agent run.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LMSTUDIO_URL="${LMSTUDIO_URL:-http://127.0.0.1:1234/v1}"
ERR=0

check() {
  local label="$1"
  local ok="$2"
  if [[ "$ok" == "yes" ]]; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    ERR=1
  fi
}

echo "repo_root=$REPO_ROOT"
echo "lmstudio_url=$LMSTUDIO_URL"
echo

if command -v pi >/dev/null 2>&1; then
  check "pi installed ($(pi --version 2>/dev/null || echo unknown))" yes
else
  check "pi installed (npm install -g @earendil-works/pi-coding-agent)" no
fi

if [[ -f "$REPO_ROOT/.cursor/skills/iago-daily/SKILL.md" ]]; then
  check "iago skills at repo root" yes
else
  check "iago skills at repo root" no
fi

if [[ -L "$REPO_ROOT/.pi/skills/iago-daily" || -f "$REPO_ROOT/.pi/skills/iago-daily/SKILL.md" ]]; then
  check "pi project skills linked" yes
else
  check "pi project skills linked (run install-pi-skills.sh)" no
fi

if [[ -f "${HOME}/.pi/agent/models.json" ]]; then
  check "pi models.json present" yes
else
  check "pi models.json present (~/.pi/agent/models.json)" no
fi

if curl -m 5 -sf "${LMSTUDIO_URL}/models" >/dev/null 2>&1; then
  check "LM Studio server responding" yes
  model_count="$(curl -m 5 -sf "${LMSTUDIO_URL}/models" | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("data",[])))' 2>/dev/null || echo 0)"
  echo "     models listed: $model_count"
else
  check "LM Studio server responding (open LM Studio → Local Server → Start Server)" no
fi

if [[ -f "$REPO_ROOT/data/config.yaml" ]]; then
  check "data/config.yaml present" yes
else
  check "data/config.yaml present (run iago-setup or init-data.sh)" no
fi

echo
if [[ "$ERR" -eq 0 ]]; then
  echo "All checks passed. Try:"
  echo "  cd \"$REPO_ROOT\" && pi --approve"
  echo "  /skill:iago-daily"
  exit 0
fi

echo "Fix the failures above, then re-run this script."
exit 1
