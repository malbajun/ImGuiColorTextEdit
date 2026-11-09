#!/usr/bin/env bash
set -euo pipefail
umask 022

test "$(id -u)" -eq 0
test -d /sources/ci/alt-hasher
if ! test -w /sys/fs/cgroup/cgroup.procs; then
    echo 'The container needs a writable private cgroup2; rootless Docker cannot provide it here.' >&2
    exit 1
fi

# Keep ALT's official sources, keyring and package verification enabled.
apt-get -o Acquire::Retries=2 -o Acquire::http::Timeout=40 update
apt-get -y -o Acquire::Retries=2 -o Acquire::http::Timeout=40 \
    install gear hasher hasher-priv util-linux
rpm -q gear hasher hasher-priv > /results/tool-versions.txt

useradd --create-home --uid "${ALT_BUILDER_UID:-1000}" builder
hasher-useradd builder
builder_config="/etc/hasher-priv/user.d/$(id -u builder)"
if ! test -f "$builder_config"; then
    builder_config=/etc/hasher-priv/user.d/builder
fi
printf '\nallowed_mountpoints=/proc\n' >> "$builder_config"
chown root:hashman "$builder_config"
chmod 0640 "$builder_config"
mkdir -p /home/builder/hasher /sys/fs/cgroup/hasher.scope
chown builder:builder /home/builder/hasher /sys/fs/cgroup/hasher.scope \
    /sys/fs/cgroup/hasher.scope/cgroup.procs
if test -e /sys/fs/cgroup/hasher.scope/cgroup.threads; then
    chown builder:builder /sys/fs/cgroup/hasher.scope/cgroup.threads
fi
chown builder:builder /results
chmod 0755 /results

hasher-privd --loglevel debug > /results/hasher-privd.log 2>&1 </dev/null &
helper_pid=$!
for ((attempt=0; attempt<100; attempt++)); do
    kill -0 "$helper_pid"
    if test -S /run/hasher-priv/daemon; then
        exit 0
    fi
    sleep 0.1
done
echo 'hasher-privd did not create its control socket.' >&2
exit 1
