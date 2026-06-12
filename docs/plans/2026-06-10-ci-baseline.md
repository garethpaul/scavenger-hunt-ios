# CI Baseline

Status: Completed

## Context

The repository had a local static `make check` baseline for Mapbox token,
workspace, location, signing, and asset contracts, but no hosted workflow ran
it for pushes and pull requests. Linux runners cannot compile this historical
iOS workspace, so the hosted gate deliberately enforces only portable source
contracts while Xcode builds remain a separate platform-specific check.

## Changes

- Added a GitHub Actions workflow that installs Ruby 3.3 and runs `make check`.
- Pinned Node 24-compatible checkout and Ruby setup actions by verified SHA.
- Restricted workflow permissions to read-only contents and bounded the job to
  five minutes while disabling checkout credential persistence.
- Extended the iOS contract checker and docs so the hosted CI path stays
  visible.

## Verification

- `ruby -c scripts/check_ios_contract.rb`
- `make check`
- `git diff --check`
