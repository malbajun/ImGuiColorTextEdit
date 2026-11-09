"""Expose bounded CI diagnostics in check annotations as well as artifacts."""

from pathlib import Path

results = Path("artifacts/alt-hasher")
for name in (
    "docker-security.json", "runner.log", "setup.log", "smoke.log",
    "imgui-build.log", "editor-build.log", "imgui-provides.txt",
    "install.log", "consumer.log", "hasher-privd.log",
    "geogram-dependencies.log", "geogram.log", "geogram-configure.log",
    "evidence.json",
):
    path = results / name
    if not path.is_file():
        continue
    lines = 80 if name == "geogram-configure.log" else 20
    tail = "\n".join(path.read_text(errors="replace").splitlines()[-lines:])[-5000:]
    message = f"{name}:\n{tail}"
    escaped = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::error title=ALT hasher diagnostic::{escaped}")
