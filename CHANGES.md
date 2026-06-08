# Changes

## 2026-06-08

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
