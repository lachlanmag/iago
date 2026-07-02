#!/usr/bin/env bash
# Merge missing keys from examples/config.example.yaml into data/config.yaml.
# Existing values are never overwritten. Safe to re-run.
#
# Usage:
#   bash scripts/reconcile-config.sh           # apply merge
#   bash scripts/reconcile-config.sh --dry-run # preview keys to add
#
# Requires: pip3 install ruamel.yaml

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$REPO_ROOT/scripts/reconcile-config.py" "$@"
