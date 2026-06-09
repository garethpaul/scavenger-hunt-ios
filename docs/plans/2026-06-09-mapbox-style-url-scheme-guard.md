# Mapbox Style URL Scheme Guard

## Status: Completed

## Context

The app can now read an optional `MAPBOX_STYLE_URL` from local configuration.
The helper ignored blank or unresolved build placeholders, but any syntactically
valid URL scheme could still be passed to Mapbox. Local style configuration
should stay constrained to expected Mapbox or HTTPS style references.

## Objectives

- Preserve blank and unresolved-placeholder fallback to Mapbox's default style.
- Allow locally configured `mapbox` and `https` style URLs.
- Ignore configured style URLs with unexpected schemes.
- Add deterministic static validation for the scheme allowlist.

## Work Completed

- Added a `mapbox`/`https` scheme allowlist in `configuredMapStyleURL()`.
- Updated the local secrets template comment to document accepted schemes.
- Extended `scripts/check_ios_contract.rb` to require the style URL scheme
  guard.
- Updated README, VISION, and CHANGES notes for the scheme guard.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make lint`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

`xcodebuild` is not installed in this environment, so `make check` reports that
the compile check was not run after static verification passes.
