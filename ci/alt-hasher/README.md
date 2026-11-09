# ALT hasher runner check

This first workflow verifies the environment before enabling package builds.
It runs on pushes to `ci/alt-hasher` and can be dispatched manually after GitHub
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

After this check passes, package jobs can use `gear-hsh` to build the maintainer
`libimgui` branch `sis_in` and then the editor's `packaging/alt` branch, retaining
the local hasher repository between them. Geogram integration follows the RPM
installation check. The maintainer dependency is never patched automatically.

There is a separate dependency issue to resolve before claiming a green package
build: `libimgui` commit `5b8039ba3318d964d790859ae3b6330931d822bb` has a 1.93.0
spec but declares 1.91.5 in CMake. This runner check deliberately does not hide
that issue or substitute another source for the requested dependency.
