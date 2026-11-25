# Shared data-folder helpers, sourced by Iago scripts (bash 3.2 compatible).
#
# data/ is either a plain in-repo folder or a per-machine symlink to a folder
# outside the repo. link-data.sh records the chosen folder in this clone's git
# config (iago.dataDir), so a git checkout that replaces or removes the
# symlink is detected instead of silently starting a fresh, empty data/.

# Print this clone's configured data folder (absolute path), or nothing.
# Silent no-op when git is unavailable or the repo is not a git checkout.
iago_configured_dir() {
  local repo="$1"
  command -v git >/dev/null 2>&1 || return 0
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || return 0
  git -C "$repo" config --local --get iago.dataDir 2>/dev/null || true
}

# Print the data/ mode: missing, in-repo, linked, broken, other (a non-folder
# named data), or unlinked (a folder is configured but data/ does not point
# at it). Pass an empty configured folder to get the physical state only.
iago_data_mode() {
  local data="$1/data" conf="${2:-}"
  if [[ -L "$data" && ! -d "$data" ]]; then
    echo broken
  elif [[ -e "$data" && ! -d "$data" ]]; then
    echo other
  elif [[ -n "$conf" ]] && ! { [[ -L "$data" ]] && [[ "$data" -ef "$conf" ]]; }; then
    echo unlinked
  elif [[ -L "$data" ]]; then
    echo linked
  elif [[ -d "$data" ]]; then
    echo in-repo
  else
    echo missing
  fi
}

# One-line fix-it message for a problem mode (same wording everywhere).
# Args: mode repo configured
iago_data_hint() {
  local mode="$1" repo="$2" conf="${3:-}"
  local ask='(or ask in chat: "change my Iago data folder")'
  case "$mode" in
    broken)
      echo "data -> $(readlink "$repo/data") does not exist. Mount or sync that folder, or run: bash scripts/link-data.sh <folder> $ask" ;;
    unlinked)
      echo "data/ is not linked to the configured folder $conf. Run: bash scripts/link-data.sh \"$conf\" $ask" ;;
    other)
      echo "data is a file, not a folder. Move it aside, then run: bash scripts/link-data.sh <folder> $ask" ;;
  esac
}

# Fail fast (status 4) when data/ is a broken symlink or is not linked to this
# clone's configured folder. Usage: iago_require_data_dir "$REPO_ROOT" || exit $?
iago_require_data_dir() {
  local repo="$1" conf mode
  conf="$(iago_configured_dir "$repo")"
  mode="$(iago_data_mode "$repo" "$conf")"
  case "$mode" in
    broken|unlinked)
      echo "error: $(iago_data_hint "$mode" "$repo" "$conf")" >&2
      return 4 ;;
  esac
  return 0
}
