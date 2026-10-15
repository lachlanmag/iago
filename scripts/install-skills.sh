#!/usr/bin/env bash
# Symlink Iago project skills into ~/.cursor/skills/ and/or ~/.claude/skills/
# for global discovery. Use when the workspace root is a parent folder (monorepo,
# notes + code) rather than this repo. Safe to re-run: updates existing symlinks.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--platform cursor|claude|hermes|both]

Install Iago skills as symlinks in your home directory.

Platforms:
  cursor  Symlink .cursor/skills/* → ~/.cursor/skills/* (default)
  claude  Symlink .claude/skills/* → ~/.claude/skills/*
  hermes  Symlink .hermes/skills/* → \${HERMES_HOME:-~/.hermes}/skills/*
  both    Install for Cursor, Claude Code, and Hermes Agent (all platforms)
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
  cursor|claude|hermes|both) ;;
  *)
    echo "error: invalid platform: $platform (expected cursor, claude, hermes, or both)" >&2
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

install_hermes() {
  echo "=== Hermes Agent ==="
  local hermes_dest="${HERMES_HOME:-$HOME/.hermes}/skills"
  install_platform "$REPO_ROOT/.hermes/skills" "$hermes_dest"
  echo "New Hermes sessions will discover skills automatically; restart Hermes to pick up updates in an already-running session."
}

install_all() {
  install_cursor
  echo
  install_claude
  echo
  install_hermes
}

case "$platform" in
  cursor)
    install_cursor
    ;;
  claude)
    install_claude
    ;;
  hermes)
    install_hermes
    ;;
  both)
    install_all
    ;;
esac
