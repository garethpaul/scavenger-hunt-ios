# When-In-Use Location Scope

## Status: Completed

## Context

The app only needs visible, foreground map tracking for the proposal flow. The
existing source requests when-in-use location authorization and gates Mapbox
tracking on authorization, but the static checker did not reject future
always-on location prompts or plist usage descriptions.

## Objectives

- Preserve the current when-in-use authorization flow.
- Reject always-on location authorization requests in Swift source.
- Reject always-location usage-description keys in the checked-in plist.
- Avoid changing Mapbox behavior or prize-marker coordinates in this focused
  privacy pass.

## Work Completed

- Extended `scripts/check_ios_contract.rb` to reject
  `requestAlwaysAuthorization()`.
- Extended the plist check to reject always-location usage-description keys.
- Updated README, VISION, and CHANGES notes for the when-in-use location scope
  guard.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `git diff --check`

## Xcode Notes

This change only updates static privacy validation. The repository `make check`
wrapper still runs `xcodebuild` when that tool is available locally.
