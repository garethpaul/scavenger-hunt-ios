# Mapbox Style URL Authority

## Status: Completed

## Context

The local style URL helper allowed only `mapbox` and `https` schemes, but a
scheme alone did not make the URL usable. Values such as `https:broken` had no
host, and non-style `mapbox://` authorities could pass validation.

## Objectives

- Require `mapbox://styles/...` for Mapbox style URLs.
- Require a non-empty host for HTTPS style URLs.
- Preserve blank configuration as the Mapbox default-style behavior.

## Work Completed

- Added scheme-specific authority validation to `configuredMapStyleURL()`.
- Extended the dependency-free iOS contract checker.
- Updated README, SECURITY, VISION, and CHANGES guidance.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `make verify`
- `git diff --check`

## Legacy Build Notes

The archived Xcode build remains opt-in through `RUN_LEGACY_XCODE=1` on a
compatible macOS toolchain.
