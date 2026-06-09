# Authorized User Tracking

## Status: Completed

## Context

`ViewController` requested when-in-use location authorization, but it also set
Mapbox user tracking to `.follow` during map setup. User-following mode should
only be enabled after the app has a compatible authorization status.

## Objectives

- Preserve the existing map center, prize annotation, and location permission
  request flow.
- Enable Mapbox user tracking only after when-in-use or always authorization is
  available.
- Retry user tracking when location authorization changes.
- Extend the static iOS contract checker to preserve the gated tracking path.

## Work Completed

- Moved `.follow` tracking into `enableUserTrackingIfAuthorized()`.
- Checked `CLLocationManager.authorizationStatus()` before enabling tracking.
- Added `locationManager(_:didChangeAuthorization:)` to retry after permission
  changes.
- Extended `scripts/check_ios_contract.rb` to reject direct tracking assignment.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

`xcodebuild` was not available in this environment, so simulator build
verification was not run here. The repository `make check` wrapper still runs
`xcodebuild` when that tool is available locally.
