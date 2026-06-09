# Mapbox Style URL Configuration

## Status: Completed

## Context

The app already keeps Mapbox access tokens out of source control, but the map
style path was still represented in Swift as an unconditional `nil` value. That
made the default-style behavior safe, but it left no checked-in contract for
local custom styles and no guard against future hardcoded private style URLs.

## Objectives

- Allow an optional Mapbox style URL to come from local configuration.
- Treat blank or unresolved build-setting placeholders as "use the Mapbox
  default style."
- Reject checked-in Mapbox style URLs in Swift source or `Info.plist`.
- Keep the existing map center, annotation, and location-permission behavior.

## Work Completed

- Added a `MAPBOX_STYLE_URL` plist build-setting placeholder.
- Added the optional `MAPBOX_STYLE_URL` entry to the local secrets template.
- Updated `ViewController` to resolve a configured style URL at runtime and
  ignore blank or unresolved placeholders.
- Extended `scripts/check_ios_contract.rb` to require the configuration path
  and reject hardcoded `mapbox://styles/` values.
- Updated README, VISION, and CHANGES with the new style URL contract.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `git diff --check`

`xcodebuild` is not installed in this environment, so `make check` reports that
the compile check was not run after static verification passes.

## Follow-Up Candidates

- Run simulator verification on macOS with Xcode after setting a local
  `MAPBOX_STYLE_URL`.
- Consider moving demo coordinates into local configuration if this sample is
  reused beyond the original proposal flow.
