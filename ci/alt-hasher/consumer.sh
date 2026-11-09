#!/usr/bin/env bash
set -euo pipefail
test "$(id -un)" = builder
mkdir -p /home/builder/consumer
cat > /home/builder/consumer/CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.14)
project(InstalledEditorCheck LANGUAGES CXX)
find_package(ImGuiColorTextEdit CONFIG REQUIRED)
add_executable(installed-editor /sources/tests/editor-regression.cpp)
target_link_libraries(installed-editor PRIVATE ImGuiColorTextEdit::ImGuiColorTextEdit)
enable_testing()
add_test(NAME installed-editor COMMAND installed-editor)
EOF
cmake -S /home/builder/consumer -B /home/builder/consumer-build
cmake --build /home/builder/consumer-build --parallel 4
ctest --test-dir /home/builder/consumer-build --output-on-failure
printf '%s\n' 'Installed RPMs compiled and passed the consumer checks.' \
    > /results/installed-consumer.ok
