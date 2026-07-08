#!/usr/bin/env bash
# Symlink Iago project skills into ~/.cursor/skills/ for global discovery.
# Use when the Cursor workspace root is a parent folder (monorepo, notes + code)
# rather than this repo. Safe to re-run: updates existing symlinks.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/.cursor/skills"
DEST="${HOME}/.cursor/skills"

if [[ ! -d "$SRC" ]]; then
  echo "error: skills not found at $SRC" >&2
  exit 1
fi

mkdir -p "$DEST"

installed=0
updated=0
skipped=0

for skill_dir in "$SRC"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  target="$DEST/$name"

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

echo
echo "Skills source: $SRC"
echo "Skills target: $DEST"
echo "installed=$installed updated=$updated skipped=$skipped"
echo "Reload Cursor: Cmd+Shift+P → Developer: Reload Window"
