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
regression checks against the installed packages. Geogram integration can follow
once the RPM stage passes. The maintainer dependency is never patched automatically.

The final evidence step requires all four runtime/devel RPMs with valid RPM
magic, all stage-completion markers, and the input revision record. It saves
filenames, byte counts and SHA-256 digests in `evidence.json` and a check annotation.

`run.sh` defaults to the environment check alone; set
`ALT_HASHER_BUILD_PACKAGES=1` to run the package/installation stages as CI does.

There is a separate dependency issue to resolve before claiming a green package
build: `libimgui` commit `5b8039ba3318d964d790859ae3b6330931d822bb` has a 1.93.0
spec but declares 1.91.5 in CMake. This runner check deliberately does not hide
that issue or substitute another source for the requested dependency.
