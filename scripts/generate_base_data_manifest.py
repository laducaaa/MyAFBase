#!/usr/bin/env python3
"""Print SHA-256 hashes for base_data_manifest.json entries."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASES_DIR = ROOT / "MyAFBase/MyAFBase/Resources/Bases"
MANIFEST_PATH = ROOT / "MyAFBase/MyAFBase/Resources/BaseData/base_data_manifest.json"


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    files = {"bases_index.json": sha256_file(BASES_DIR / "bases_index.json")}
    for path in sorted(BASES_DIR.glob("*.json")):
        if path.name.startswith("_"):
            continue
        files[path.name] = sha256_file(path)

    manifest = {"files": files}
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(files)} hashes to {MANIFEST_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
