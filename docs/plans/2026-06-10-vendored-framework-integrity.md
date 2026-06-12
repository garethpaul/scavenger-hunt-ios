# Vendored Framework Integrity

Status: Completed

## Context

The repository checks in CocoaPods 1.1.1 output and a 41 MiB Mapbox iOS SDK
3.1.2 framework binary. `Podfile.lock` and `Pods/Manifest.lock` agree, but those
text files did not detect changes to the vendored executable itself. The Swift,
Xcode, CocoaPods, and Mapbox versions are archival and do not justify an
automatic build attempt on every modern macOS host.

## Objectives

- Record and enforce the vendored Mapbox framework binary's SHA-256 digest.
- Keep hosted validation dependency-free and structural.
- Make legacy Xcode compilation explicit rather than host-dependent.
- Fix the hosted runner and preserve immutable action revisions.
- Keep `make check` independent of the caller's working directory.

## Work Completed

- Added `VENDORED_FRAMEWORKS.sha256` for the checked-in Mapbox executable.
- Extended the iOS contract to reject framework binary drift.
- Changed Xcode compilation to an explicit `RUN_LEGACY_XCODE=1` opt-in.
- Fixed GitHub Actions to Ubuntu 24.04 with concurrency cancellation.
- Annotated checkout v6.0.3 and setup-ruby v1.312.0 immutable commits.
- Anchored Makefile and checker execution to the repository root.

## Verification

- `make check`
- `make -f /path/to/repository/Makefile check` from outside the repository
- `sha256sum -c VENDORED_FRAMEWORKS.sha256`
- `git diff --check`
