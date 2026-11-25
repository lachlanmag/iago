# Sourced by Iago scripts. Fails fast when data/ is a symlink to a folder that
# is not there (sync drive unmounted, folder renamed) instead of silently
# creating a fresh, empty data/.
iago_require_data_dir() {
  local repo="$1" data="$1/data"
  if [[ -L "$data" && ! -d "$data" ]]; then
    echo "error: data -> $(readlink "$data") does not exist." >&2
    echo "  Mount or sync that folder, or point Iago elsewhere:" >&2
    echo "  bash \"$repo/scripts/link-data.sh\" <folder>   (or ask: \"change my Iago data folder\")" >&2
    return 4
  fi
}
