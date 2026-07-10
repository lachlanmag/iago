#!/usr/bin/env bash
# Wire Iago skills into Pi (local agent with LM Studio).
# Pi uses the same Agent Skills standard as Cursor (.cursor/skills/*/SKILL.md).
# Safe to re-run.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/.cursor/skills"
PI_AGENT="${HOME}/.pi/agent"
PI_PROJECT="$REPO_ROOT/.pi"
PI_SKILLS="$PI_PROJECT/skills"
SETTINGS="$PI_AGENT/settings.json"

if [[ ! -d "$SRC" ]]; then
  echo "error: skills not found at $SRC" >&2
  exit 1
fi

if ! command -v pi >/dev/null 2>&1; then
  echo "error: pi not found. Install with: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
fi

mkdir -p "$PI_AGENT" "$PI_PROJECT"

# Project-level skill symlinks (.pi/skills -> .cursor/skills)
mkdir -p "$PI_SKILLS"
installed=0
updated=0
skipped=0

for skill_dir in "$SRC"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  target="$PI_SKILLS/$name"

  if [[ ! -f "$skill_dir/SKILL.md" ]]; then
    echo "skip (no SKILL.md): $name" >&2
    ((skipped++)) || true
    continue
  fi

  if [[ -L "$target" ]]; then
    ln -sfn "$skill_dir" "$target"
    echo "updated: $name"
    ((updated++)) || true
  elif [[ -e "$target" ]]; then
    echo "skip (exists, not a symlink): $target" >&2
    ((skipped++)) || true
  else
    ln -s "$skill_dir" "$target"
    echo "installed: $name"
    ((installed++)) || true
  fi
done

# Merge skills paths into ~/.pi/agent/settings.json (preserve other keys)
python3 << 'PY'
import json
import os
from pathlib import Path

settings_path = Path(os.environ["SETTINGS"])
repo_root = Path(os.environ["REPO_ROOT"])
cursor_skills = Path.home() / ".cursor" / "skills"
project_skills = repo_root / ".pi" / "skills"

data = {}
if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text())
    except json.JSONDecodeError:
        pass

skills = data.get("skills", [])
for path in (str(cursor_skills), str(project_skills)):
    if path not in skills:
        skills.append(path)

data["skills"] = skills
data.setdefault("defaultProvider", "lmstudio")
data.setdefault("defaultModel", "qwen/qwen3.5-9b")
data.setdefault("enableSkillCommands", True)

settings_path.parent.mkdir(parents=True, exist_ok=True)
settings_path.write_text(json.dumps(data, indent=2) + "\n")
print(f"updated: {settings_path}")
PY

echo
echo "Skills source: $SRC"
echo "Project skills: $PI_SKILLS"
echo "Pi settings: $SETTINGS"
echo "installed=$installed updated=$updated skipped=$skipped"
echo
echo "Next: start LM Studio server, then run: bash \"$REPO_ROOT/scripts/verify-lm-studio.sh\""
