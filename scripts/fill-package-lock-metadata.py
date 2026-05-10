#!/usr/bin/env python3
"""Fill npm package-lock entries with tarball metadata needed by Nix.

Some upstream npm versions emit package-lock entries without `resolved` and
`integrity`. Nix's buildNpmPackage installs from an offline cache populated from
those fields, so missing metadata causes ENOTCACHED during the sandboxed build.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def package_name(lock_key: str) -> str | None:
    marker = "node_modules/"
    if marker not in lock_key:
        return None
    return lock_key.rsplit(marker, 1)[1]


def npm_dist(name: str, version: str) -> dict[str, str]:
    result = subprocess.run(
        ["npm", "view", "--json", f"{name}@{version}", "dist"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    data = json.loads(result.stdout)
    return {
        "resolved": data["tarball"],
        "integrity": data["integrity"],
    }


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <package-lock.json>", file=sys.stderr)
        return 2

    lockfile = Path(sys.argv[1])
    data = json.loads(lockfile.read_text())
    packages = data.get("packages", {})
    cache: dict[tuple[str, str], dict[str, str]] = {}
    changed = 0

    for key, entry in packages.items():
        if not isinstance(entry, dict):
            continue
        if entry.get("resolved") and entry.get("integrity"):
            continue
        version = entry.get("version")
        name = package_name(key)
        if not name or not version:
            continue

        dist_key = (name, version)
        if dist_key not in cache:
            cache[dist_key] = npm_dist(name, version)
        entry.update(cache[dist_key])
        changed += 1

    if changed:
        lockfile.write_text(json.dumps(data, indent="\t") + "\n")
    print(f"filled metadata for {changed} package-lock entries", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
