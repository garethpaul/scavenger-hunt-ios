# Changes

## 2026-06-08

- Added a static iOS contract check for Mapbox token placeholders, image assets,
  CocoaPods lock consistency, and optional Xcode build execution.
- Replaced the checked-in Mapbox access token with the `$(MAPBOX_ACCESS_TOKEN)`
  build-setting placeholder.
- Added an ignored `MapboxSecrets.xcconfig` template for local token setup.
- Fixed the blank Mapbox style URL and the location permission typo.
