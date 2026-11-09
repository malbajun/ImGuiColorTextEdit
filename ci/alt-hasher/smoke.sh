#!/usr/bin/env bash
set -euo pipefail

test "$(id -un)" = builder
test "$HOME" = /home/builder
# hasher-privd joins the caller's cgroup. Delegate only this container's child.
cat /proc/self/cgroup > /results/builder-cgroup.txt
grep -q '^0::/hasher.scope$' /results/builder-cgroup.txt

hsh --initroot-only --workdir=/home/builder/hasher --nprocs=4 --verbose
hsh-run --workdir=/home/builder/hasher --mountpoints=/proc -- /bin/sh -ec \
    'id; rpm -q basesystem rpm-build; test -d /proc/self; uname -m'
printf '%s\n' 'Clean hasher chroot initialized and executed successfully.' \
    > /results/hasher-initroot.ok
