#!/usr/bin/env bash
set -euo pipefail
test "$(id -un)" = builder
test -s /results/installed-consumer.ok

root=/home/builder/geogram
prefix=/home/builder/geogram-install
collect_configure_log() {
    status=$?
    trap - EXIT
    if test -f /home/builder/geogram-build/CMakeFiles/CMakeConfigureLog.yaml; then
        cp /home/builder/geogram-build/CMakeFiles/CMakeConfigureLog.yaml \
            /results/geogram-configure.log
    fi
    exit "$status"
}
trap collect_configure_log EXIT
git clone --single-branch --branch feature/external-text-editor \
    https://github.com/malbajun/geogram.git "$root"
git -C "$root" log -1 --format='geogram: %H %s' \
    | tee -a /results/input-revisions.txt
git -C "$root" submodule update --init --depth 1 \
    src/lib/geogram/third_party/OpenNL src/lib/geogram/third_party/amgcl \
    src/lib/geogram/third_party/libMeshb src/lib/geogram/third_party/rply \
    src/lib/geogram_gfx/third_party/imgui src/lib/geogram_gfx/third_party/imoguizmo \
    src/lib/geogram_gfx/third_party/imgui_lua_bindings_gomgen

# This stage checks the application integration on ALT; the preceding library
# RPMs are built by gear-hsh. Geogram itself is not represented as an RPM here.
cmake -S "$root" -B /home/builder/geogram-build \
    -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DGEOGRAM_USE_SYSTEM_TEXT_EDITOR=ON -DGEOGRAM_USE_SYSTEM_GLFW3=ON \
    -DGEOGRAM_WITH_LUA=ON -DGEOGRAM_LIB_ONLY=ON -DVORPALINE_BUILD_DYNAMIC=ON
cmake --build /home/builder/geogram-build --parallel 4
cmake --install /home/builder/geogram-build --component devkit
cmake --install /home/builder/geogram-build --component devkit-full

cmake -S "$root/tests/standalone-text-editor" -B /home/builder/geogram-consumer \
    -DGEOGRAM_INSTALL_PREFIX="$prefix" \
    -DCMAKE_MODULE_PATH="$prefix/lib/cmake/modules" -DGEOGRAM_CHECK_LUA=ON
cmake --build /home/builder/geogram-consumer --parallel 4
LD_LIBRARY_PATH="$prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    ctest --test-dir /home/builder/geogram-consumer --output-on-failure \
        --output-junit /results/geogram-consumer-tests.xml
printf '%s\n' 'Geogram and its installed editor/Lua consumers passed with the installed ALT library RPMs.' \
    > /results/geogram-integration.ok
