"""Require real RPM outputs and completed installed-consumer checks."""

import hashlib
import json
from pathlib import Path
import re
import sys

results = Path(sys.argv[1] if len(sys.argv) > 1 else "artifacts/alt-hasher")
errors = []
for name in ("hasher-initroot.ok", "rpm-builds.ok", "installed-consumer.ok", "input-revisions.txt"):
    path = results / name
    if not path.is_file() or not path.stat().st_size:
        errors.append(f"missing or empty {name}")

packages = []
for path in sorted((results / "rpms").glob("*.rpm")):
    if path.name.endswith(".src.rpm") or "-debuginfo-" in path.name:
        continue
    with path.open("rb") as stream:
        magic = stream.read(4)
    if magic != bytes.fromhex("edabeedb") or path.stat().st_size < 96:
        errors.append(f"invalid RPM file: {path.name}")
    packages.append({
        "name": path.name,
        "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    })

for name in ("libimgui", "libimgui-devel", "libImGuiColorTextEdit", "libImGuiColorTextEdit-devel"):
    pattern = re.compile(rf"^{re.escape(name)}-[0-9]")
    if not any(pattern.match(package["name"]) for package in packages):
        errors.append(f"no binary RPM for {name}")

evidence = {"valid": not errors, "errors": errors, "packages": packages}
results.mkdir(parents=True, exist_ok=True)
(results / "evidence.json").write_text(json.dumps(evidence, indent=2) + "\n")
message = json.dumps(evidence)
escaped = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
level = "error" if errors else "notice"
print(f"::{level} title=ALT RPM evidence::{escaped}")
sys.exit(1 if errors else 0)
