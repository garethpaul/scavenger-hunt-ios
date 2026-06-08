# Scavenger Hunt iOS Baseline

## Status: Completed

## Context

`scavenger-hunt-ios` is a legacy Swift proposal app built around a Mapbox map,
custom annotation assets, and CocoaPods-managed dependencies. Its default
maintenance gate should protect token handling, annotation safety, and asset
references even when Xcode is unavailable.

## Objectives

- Keep Mapbox tokens and local style configuration out of git.
- Validate safe annotation-title, marker-image, and location-update handling.
- Keep required marker/logo assets and asset catalog JSON consistent.
- Confirm CocoaPods lockfiles remain synchronized.
- Maintain completed maintenance plans under `docs/plans`.

## Work Completed

- Confirmed `make check` runs the static iOS contract and optional Xcode build.
- Added canonical `docs/plans` coverage for the current maintenance baseline.
- Extended the iOS contract checker to require completed `docs/plans` entries
  with `make check` verification.
- Updated README, VISION, and CHANGES to make the baseline discoverable.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `make verify`
- `git diff --check`

## Follow-Up Candidates

- Run simulator verification on macOS with Xcode before a release.
- Document whether fixed coordinates are intentional demo markers or should be
  configurable.
