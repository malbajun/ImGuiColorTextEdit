#!/usr/bin/env bash
set -euo pipefail
test -s /results/rpm-builds.ok

packages=()
while IFS= read -r -d '' package; do
    packages+=("$package")
done < <(find /results/rpms -maxdepth 1 -type f -name '*.rpm' \
    ! -name '*.src.rpm' ! -name '*-debuginfo-*' -print0)
test "${#packages[@]}" -gt 0
# Resolve runtime dependencies with APT; never use rpm --nodeps.
apt-get -y install cmake ctest gcc-c++ make "${packages[@]}"
rpm -q libimgui libimgui-devel libImGuiColorTextEdit libImGuiColorTextEdit-devel \
    > /results/installed-packages.txt
