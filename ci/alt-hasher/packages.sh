#!/usr/bin/env bash
set -euo pipefail

test "$(id -un)" = builder
grep -q '^0::/hasher.scope$' /proc/self/cgroup
workdir=/home/builder/hasher
packager=${ALT_HASHER_PACKAGER:?Set the package maintainer metadata for sisyphus_check}
mkdir -p /results/rpms

# Preserve successful dependency RPMs even if a later build fails.
collect() {
    status=$?
    trap - EXIT
    if test -d "$workdir/repo"; then
        find "$workdir/repo" -type f -name '*.rpm' \
            -exec cp -- {} /results/rpms/ \; || true
    fi
    exit "$status"
}
trap collect EXIT

git clone --single-branch --branch sis_in \
    https://git.altlinux.org/people/majioa/packages/libimgui.git /home/builder/imgui
git -c safe.directory=/sources clone --no-hardlinks /sources /home/builder/editor
{
    git -C /home/builder/imgui log -1 --format='libimgui: %H %s'
    git -C /home/builder/editor log -1 --format='editor: %H %s'
} | tee /results/input-revisions.txt

# Build exactly the maintainer source. Do not patch its CMake/spec or manufacture
# an RPM provide to satisfy the editor's version requirement.
(
    cd /home/builder/imgui
    gear-hsh --workdir="$workdir" --nprocs=4 --mountpoints=/proc --packager="$packager" --verbose
) 2>&1 | tee /results/imgui-build.log

while IFS= read -r -d '' package; do
    rpm -qp --provides "$package"
done < <(find "$workdir/repo" -type f -name 'libimgui-devel-*.rpm' -print0) \
    > /results/imgui-provides.txt
cat /results/imgui-provides.txt

(
    cd /home/builder/editor
    gear-hsh --workdir="$workdir" --nprocs=4 --mountpoints=/proc --packager="$packager" --verbose
) 2>&1 | tee /results/editor-build.log
printf '%s\n' 'Both packages built through gear-hsh.' > /results/rpm-builds.ok
