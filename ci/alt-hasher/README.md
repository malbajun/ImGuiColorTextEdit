# ALT hasher runner check

The workflow first verifies the environment, then builds packages through gear-hsh.
It runs on relevant pushes to `ci/alt-hasher` and `packaging/alt` (once included
there), and can be dispatched manually after GitHub
has registered the workflow on the default branch. No default branch merge is
required for the push trigger. It does not run on pull requests or publish RPMs.

The hosted Ubuntu 24.04 VM runs an official ALT Sisyphus container with a private,
writable cgroup namespace. Its privileged mode is confined to this disposable,
trusted CI job; the workflow token has read-only contents permission and is not
passed into Docker. A child cgroup is delegated to the ordinary hasher user.
Hasher itself, its namespace isolation and RPM signature checks are retained.

Success requires more than a live container: `hsh --initroot-only` must unpack
and initialize a clean chroot, and `hsh-run` must execute inside it and query the
installed base/RPM build packages. Failures preserve setup and helper logs in an
Actions artifact. Rootless Docker is rejected with an explicit diagnostic.

After this check passes, `packages.sh` builds the maintainer `libimgui` branch
`sis_in`, then the checked-out editor branch (based on `packaging/alt`), retaining
the local hasher repository between them. All resolved source commits are saved.
Successful dependency RPMs are preserved even if a later build fails. APT installs
the resulting RPMs, and an external CMake project compiles and runs the editor's
regression checks against the installed packages. With
`ALT_HASHER_BUILD_GEOGRAM=1`, it then builds `malbajun/geogram` branch
`feature/external-text-editor` against these installed RPMs and exercises a
consumer of its installed devkit, including the Lua/ImGui bindings. Geogram is compiled from source in this ALT
stage; it is not claimed to be an RPM build. CI enables both stages.
The maintainer dependency is never patched automatically.

The final evidence step requires all four runtime/devel RPMs with valid RPM
magic, all stage-completion markers, and the input revision record. It saves
filenames, byte counts and SHA-256 digests in `evidence.json` and a check annotation.

`run.sh` defaults to the environment check alone; set
`ALT_HASHER_BUILD_PACKAGES=1 ALT_HASHER_BUILD_GEOGRAM=1` to run all CI stages.
`ALT_HASHER_PACKAGER` sets the RPM Packager metadata required by Sisyphus checks;
its default is the existing package maintainer from the supplied ALT specs.
This is metadata, not a package signature or publication to ALT repositories.

The selected `libimgui` commit `5b8039ba3318d964d790859ae3b6330931d822bb`
has a 1.93.0 spec but declares 1.91.5 in CMake. The editor checks the actual
`libimgui-devel` RPM version and separately requires its CMake configuration.
Legacy configurations export include paths through `imgui_INCLUDE_DIRS`; the
editor propagates those to the imported dependency target when necessary.
Neither workaround modifies the maintainer source or invents an RPM provide.

ALT ships the CTest driver in the separate `ctest` package. Both the editor's
build requirements and the installed-consumer environment require it explicitly.
