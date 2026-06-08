# Mapbox Token Contract

## Problem

The app had a checked-in Mapbox access token, a blank style URL, and a typo in
the location permission message. The repository had no static gate to protect
asset references, token placeholders, or CocoaPods lock consistency when Xcode
is unavailable.

## TDD Evidence

1. Added `scripts/check_ios_contract.rb` and wired it to `make lint`.
2. Ran the checker before source fixes and confirmed it failed on the checked-in
   token, missing `$(MAPBOX_ACCESS_TOKEN)` placeholder, trailing plist key
   whitespace, location string typo, and blank style URL.
3. Replaced the token with a build-setting placeholder, added a local config
   template, fixed the source/plist issues, and reran the gate.

## Verification

- `make lint`
- `make test`
- `make build`
- `make verify`
- `git diff --check`

`xcodebuild` is not installed in this environment, so the build target reports
that the compile check was not run after static verification passes.
