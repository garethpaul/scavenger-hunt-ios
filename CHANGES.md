# Changes

## 2026-06-09

- Added a shared Xcode scheme, removed tracked developer-local Xcode user
  state, and made the workspace reference the project relatively.
- Added static privacy checks that reject always-on location authorization
  prompts and plist keys.
- Gated Mapbox user-following mode on location authorization and added static
  validation so tracking is retried only after authorization changes.
- Guarded the prize annotation so repeated view appearances do not add duplicate
  map markers.
- Extended the iOS contract checker to preserve the single-prize-marker
  behavior.

## 2026-06-08

- Removed precise coordinate logging from the location update callback and
  added static validation to prevent it from returning.
- Added an explicit when-in-use location authorization request before Mapbox
  user-location tracking and made the iOS contract checker preserve it.
- Added `make check` as the shared repository verification alias.
- Removed crash-prone force unwraps in the Mapbox annotation-image path and
  location update handler.
- Extended the iOS contract checker to require safe annotation title handling,
  guarded marker-image loading, fallback reuse identifiers, and the required
  marker/logo assets.
- Added a static iOS contract check for Mapbox token placeholders, image assets,
  CocoaPods lock consistency, and optional Xcode build execution.
- Replaced the checked-in Mapbox access token with the `$(MAPBOX_ACCESS_TOKEN)`
  build-setting placeholder.
- Added an ignored `MapboxSecrets.xcconfig` template for local token setup.
- Fixed the blank Mapbox style URL and the location permission typo.
- Added canonical `docs/plans` coverage and made the iOS contract checker
  require completed plans.
