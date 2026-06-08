# Safe Annotation Rendering

## Problem

The Mapbox annotation image delegate force-unwrapped annotation titles and
marker images. A missing title, missing marker asset, or user-location callback
could crash the sample instead of falling back to a default marker or declining
to provide an annotation image.

## TDD Evidence

1. Extended `scripts/check_ios_contract.rb` to reject force-unwrapped annotation
   titles, force-unwrapped marker images, force-unwrapped location updates, and
   missing required marker/logo assets.
2. Updated the delegate to flatten optional Mapbox titles, guard marker image
   loading, and use the marker image name as a fallback reuse identifier.
3. Updated the location callback to use the `didUpdateLocations` payload without
   force-unwrapping `manager.location`.

## Verification

- `make lint`
- `make verify`
- `git diff --check`

XcodeBuildMCP is not exposed in this Codex session, and `make build` reports
whether local `xcodebuild` is available. Simulator verification should be run on
a macOS workstation with Xcode before a production release.
