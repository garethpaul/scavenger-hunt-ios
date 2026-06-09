# Local Signing Team Guard

## Status: Completed

## Context

The Xcode project carried a concrete `DEVELOPMENT_TEAM` value. That team ID is
account-specific signing metadata, so it should be configured locally rather
than committed into the shared historical sample.

## Objectives

- Leave Xcode signing team selection to local developer configuration.
- Keep the shared project file usable for simulator builds and source review.
- Extend static verification so non-empty `DEVELOPMENT_TEAM` values do not
  return.
- Preserve the existing workspace, scheme, Mapbox token, and location guards.

## Work Completed

- Cleared the app target `DEVELOPMENT_TEAM` values in
  `TreasureHunt.xcodeproj/project.pbxproj`.
- Extended `scripts/check_ios_contract.rb` to reject non-empty
  `DEVELOPMENT_TEAM` assignments.
- Updated README, SECURITY, VISION, and CHANGES notes.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make lint`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

This environment does not provide `xcodebuild`, so the repository wrapper
reports the compile check as unavailable. Device builds should set the signing
team locally in Xcode.
