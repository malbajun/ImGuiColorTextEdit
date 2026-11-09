#!/usr/bin/env bash
set -euo pipefail
test -s /results/installed-consumer.ok

# Build Geogram against the real installed editor/ImGui RPMs. These are only
# application build dependencies, not replacements for either library.
apt-get -y install libglfw3-devel libGL-devel libGLU-devel libX11-devel \
    libXxf86vm-devel libXrandr-devel libXcursor-devel libXinerama-devel \
    libXi-devel tbb-devel libgomp-devel
