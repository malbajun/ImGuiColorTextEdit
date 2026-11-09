#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
results_dir=${ALT_HASHER_RESULTS_DIR:-"$source_dir/artifacts/alt-hasher"}
mkdir -p -- "$results_dir"
results_dir=$(cd -- "$results_dir" && pwd)

# Pin the official ALT Sisyphus base; repository packages still update normally.
image=${ALT_HASHER_IMAGE:-alt:sisyphus@sha256:113d54eb3cbf5d868563a387ebbb39edef91baed4c0e35e03f75893b57bf99ae}
container="alt-hasher-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}-$$"
builder_uid=$(id -u)
if [[ $builder_uid == 0 ]]; then
    builder_uid=1000
fi

docker info --format '{{json .SecurityOptions}}' > "$results_dir/docker-security.json"
if grep -q rootless "$results_dir/docker-security.json"; then
    echo 'This check requires the rootful Docker daemon on a hosted GitHub runner.' >&2
    exit 1
fi

cleanup() {
    result=$?
    trap - EXIT
    if docker inspect "$container" >/dev/null 2>&1; then
        docker logs "$container" > "$results_dir/container.log" 2>&1 || true
        docker rm --force "$container" >/dev/null 2>&1 || true
    fi
    exit "$result"
}
trap cleanup EXIT

# Only trusted push/manual jobs on an ephemeral VM use this container. Keep its
# cgroup namespace private and never bind the runner's whole cgroup filesystem.
# No GitHub token or other secret is passed into the container.
docker run --detach --name "$container" --privileged --cgroupns=private \
    --env "ALT_BUILDER_UID=$builder_uid" \
    --env "ALT_HASHER_PACKAGER=${ALT_HASHER_PACKAGER:-Pavel Skrylev <majioa@altlinux.org>}" \
    --mount "type=bind,src=$source_dir,dst=/sources,readonly" \
    --mount "type=bind,src=$results_dir,dst=/results" \
    "$image" sleep infinity
docker exec "$container" bash /sources/ci/alt-hasher/setup.sh \
    2>&1 | tee "$results_dir/setup.log"
docker exec --workdir /home/builder "$container" \
    bash /sources/ci/alt-hasher/as-builder.sh /sources/ci/alt-hasher/smoke.sh \
    2>&1 | tee "$results_dir/smoke.log"
test -s "$results_dir/hasher-initroot.ok"
if [[ ${ALT_HASHER_BUILD_PACKAGES:-0} == 1 ]]; then
    docker exec --workdir /home/builder "$container" \
        bash /sources/ci/alt-hasher/as-builder.sh /sources/ci/alt-hasher/packages.sh \
        2>&1 | tee "$results_dir/packages.log"
    docker exec "$container" bash /sources/ci/alt-hasher/install.sh \
        2>&1 | tee "$results_dir/install.log"
    docker exec --workdir /home/builder "$container" \
        bash /sources/ci/alt-hasher/as-builder.sh /sources/ci/alt-hasher/consumer.sh \
        2>&1 | tee "$results_dir/consumer.log"
fi
