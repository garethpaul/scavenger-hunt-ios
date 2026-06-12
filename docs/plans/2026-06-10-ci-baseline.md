# CI Baseline

Status: Completed

## Context

The repository had a local static `make check` baseline for Mapbox token,
workspace, location, signing, and asset contracts, but no hosted workflow ran
it for pushes and pull requests.

## Changes

- Added a GitHub Actions workflow that installs Ruby 3.3 and runs `make check`.
- Extended the iOS contract checker and docs so the hosted CI path stays
  visible.

## Verification

- `make check`
