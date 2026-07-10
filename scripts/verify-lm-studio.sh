#!/usr/bin/env bash
# Preflight for interactive Iago in LM Studio (khtsly/skills).
# Exit 0: wrappers present.
# Exit 1: missing wrappers or incomplete tree.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/.lmstudio/skills"

REQUIRED_SKILLS=(
  iago-daily
  iago-setup
  iago-pipeline-review
  update-application
  company-research
  interview-prep
  resume-feedback
)

echo "repo_root=$REPO_ROOT"
echo "skills_dir=$SKILLS_DIR"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "lmstudio_skills=no"
  echo "hint=Missing .lmstudio/skills; check out branch with LM Studio wrappers or re-clone." >&2
  exit 1
fi

missing=0
for name in "${REQUIRED_SKILLS[@]}"; do
  if [[ ! -f "$SKILLS_DIR/$name/SKILL.md" ]]; then
    echo "missing=$SKILLS_DIR/$name/SKILL.md" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "lmstudio_skills=incomplete"
  exit 1
fi

echo "lmstudio_skills=yes"
echo "skills_directory_path=$SKILLS_DIR"
echo "hint=Paste skills_directory_path into khtsly/skills; open LM Studio chat with workspace=$REPO_ROOT"

if [[ ! -f "$REPO_ROOT/data/config.yaml" ]]; then
  echo "config=missing"
  echo "hint=Run /iago-setup in LM Studio chat (or bash \"$REPO_ROOT/scripts/init-data.sh\" then edit data/config.yaml)"
else
  echo "config=present"
fi

exit 0
