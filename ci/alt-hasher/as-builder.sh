#!/usr/bin/env bash
set -euo pipefail
test "$(id -u)" -eq 0
test "$#" -gt 0
# Moving from the parent cgroup requires permission on the common ancestor.
# Do that as the container administrator, then run all build work unprivileged.
echo "$$" > /sys/fs/cgroup/hasher.scope/cgroup.procs

# Docker's exec pipes belong to root. Hasher reopens /dev/stderr, so inherited
# writable descriptors alone are insufficient after dropping privileges.
# Open the build log as builder, then relay it while preserving the exit code.
script=$1
log="/results/user-${script##*/}.log"
status=0
runuser --user builder -- bash -c \
    'log=$1; shift; exec bash "$@" > "$log" 2>&1' \
    bash "$log" "$@" || status=$?
if test -f "$log"; then
    cat "$log"
fi
exit "$status"
