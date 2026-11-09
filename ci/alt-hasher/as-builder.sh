#!/usr/bin/env bash
set -euo pipefail
test "$(id -u)" -eq 0
test "$#" -gt 0
# Moving from the parent cgroup requires permission on the common ancestor.
# Do that as the container administrator, then run all build work unprivileged.
echo "$$" > /sys/fs/cgroup/hasher.scope/cgroup.procs
exec runuser --user builder -- bash "$@"
