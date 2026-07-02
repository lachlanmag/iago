#!/usr/bin/env python3
"""Merge missing keys from examples/config.example.yaml into data/config.yaml.

Existing values in data/config.yaml are never overwritten. Only keys absent
from the user config are added from the example template.

Requires: pip3 install ruamel.yaml
"""

from __future__ import annotations

import argparse
import shutil
import sys
from copy import deepcopy
from datetime import datetime
from pathlib import Path

try:
    from ruamel.yaml import YAML
except ImportError:
    print(
        "reconcile-config requires ruamel.yaml (preserves YAML comments).\n"
        "Install with: pip3 install ruamel.yaml",
        file=sys.stderr,
    )
    sys.exit(1)


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def merge_missing(dst: dict, src: dict, path: str = "") -> list[str]:
    """Add keys from src that are missing in dst. dst values always win."""
    added: list[str] = []
    for key, val in src.items():
        key_path = f"{path}.{key}" if path else key
        if key not in dst:
            dst[key] = deepcopy(val)
            added.append(key_path)
        elif isinstance(dst[key], dict) and isinstance(val, dict):
            added.extend(merge_missing(dst[key], val, key_path))
    return added


def load_yaml(yaml: YAML, path: Path) -> dict:
    data = yaml.load(path.read_text())
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise SystemExit(f"Expected a YAML mapping in {path}")
    return data


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(
        description="Add missing config keys from the example template into data/config.yaml."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=root / "data" / "config.yaml",
        help="User config to update (default: data/config.yaml)",
    )
    parser.add_argument(
        "--example",
        type=Path,
        default=root / "examples" / "config.example.yaml",
        help="Example template (default: examples/config.example.yaml)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print keys that would be added without writing",
    )
    args = parser.parse_args()

    if not args.example.is_file():
        print(f"Missing example config: {args.example}", file=sys.stderr)
        return 1

    if not args.config.is_file():
        print(
            f"Missing {args.config}. Run: bash scripts/init-data.sh",
            file=sys.stderr,
        )
        return 1

    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.width = 4096

    example = load_yaml(yaml, args.example)
    user = load_yaml(yaml, args.config)
    added = merge_missing(user, example)

    if not added:
        print("No missing keys. data/config.yaml is up to date with the example template.")
        return 0

    print("Keys to add from example template:")
    for key in added:
        print(f"  + {key}")

    if args.dry_run:
        print("\nDry run: no files changed.")
        return 0

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = args.config.with_suffix(f".yaml.bak.{timestamp}")
    shutil.copy2(args.config, backup)
    print(f"\nBackup: {backup}")

    args.config.write_text("")
    with args.config.open("w") as fh:
        yaml.dump(user, fh)

    print(f"Updated: {args.config}")
    print("Review the diff and remove any redundant example keys you renamed (e.g. location_rules).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
