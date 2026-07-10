#!/usr/bin/env bash
# Symlink Iago project skills into ~/.cursor/skills/ and/or ~/.claude/skills/
# for global discovery. Use when the workspace root is a parent folder (monorepo,
# notes + code) rather than this repo. Safe to re-run: updates existing symlinks.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--platform cursor|claude|lmstudio|both]

Install or verify Iago skills for a platform.

Platforms:
  cursor    Symlink .cursor/skills/* → ~/.cursor/skills/* (default)
  claude    Symlink .claude/skills/* → ~/.claude/skills/*
  lmstudio  Verify .lmstudio/skills/* and print Skills Directory path for khtsly
  both      Install for Cursor and Claude Code (not LM Studio)
EOF
}

platform="cursor"

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
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$platform" in
  cursor|claude|lmstudio|both) ;;
  *)
    echo "error: invalid platform: $platform (expected cursor, claude, lmstudio, or both)" >&2
    usage >&2
    exit 1
    ;;
esac

install_platform() {
  local src="$1"
  local dest="$2"

  if [[ ! -d "$src" ]]; then
    echo "error: skills not found at $src" >&2
    return 1
  fi

  mkdir -p "$dest"

  local installed=0
  local updated=0
  local skipped=0

  for skill_dir in "$src"/*/; do
    [[ -d "$skill_dir" ]] || continue
    local name
    name="$(basename "$skill_dir")"
    local target="$dest/$name"

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
  echo "Skills source: $src"
  echo "Skills target: $dest"
  echo "installed=$installed updated=$updated skipped=$skipped"
}

install_cursor() {
  echo "=== Cursor ==="
  install_platform "$REPO_ROOT/.cursor/skills" "${HOME}/.cursor/skills"
  echo "Reload Cursor: Cmd+Shift+P → Developer: Reload Window"
}

install_claude() {
  echo "=== Claude Code ==="
  install_platform "$REPO_ROOT/.claude/skills" "${HOME}/.claude/skills"
  echo "Restart Claude Code session if skills do not appear"
}

REQUIRED_LMSTUDIO_SKILLS=(
  iago-daily
  iago-setup
  iago-pipeline-review
  update-application
  company-research
  interview-prep
  resume-feedback
)

install_lmstudio() {
  echo "=== LM Studio ==="
  local src="$REPO_ROOT/.lmstudio/skills"
  if [[ ! -d "$src" ]]; then
    echo "error: skills not found at $src" >&2
    return 1
  fi

  local missing=0
  local name
  for name in "${REQUIRED_LMSTUDIO_SKILLS[@]}"; do
    if [[ ! -f "$src/$name/SKILL.md" ]]; then
      echo "missing: $src/$name/SKILL.md" >&2
      missing=1
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    echo "error: incomplete .lmstudio/skills tree" >&2
    return 1
  fi

  echo "Skills Directory Path (paste into khtsly/skills plugin):"
  echo "  $src"
  echo
  echo "Next steps:"
  echo "  1. Install khtsly/skills from the LM Studio Hub"
  echo "  2. Set the plugin Skills Directory to the path above"
  echo "  3. Open LM Studio chat with workspace = $REPO_ROOT"
  echo "  4. Run: bash \"$REPO_ROOT/scripts/verify-lm-studio.sh\""
  echo "  5. In chat: /iago-setup"
  echo "Full guide: $REPO_ROOT/docs/lm-studio-setup.md"
}

case "$platform" in
  cursor)
    install_cursor
    ;;
  claude)
    install_claude
    ;;
  lmstudio)
    install_lmstudio
    ;;
  both)
    install_cursor
    echo
    install_claude
    ;;
esac
