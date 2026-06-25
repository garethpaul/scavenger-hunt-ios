# Changes

## 2026-06-25

- Stopped active location sessions and Mapbox presentation when authorization
  returns to any non-authorized state, including privacy resets to undetermined.
- Added a source contract and hostile mutation for the authorization-reset path.
- Restored the portable policy source before integration mutations so failures
  prove the controller mutation was actually rejected.

## 2026-06-21

- Isolated Make verification authority from caller-controlled file lists,
  shells, Ruby and Swift variables, Swift flags, repository roots, and trailing
  target replacements, with explicit GNU Make preload-boundary coverage.

## 2026-06-19

- Replaced the storyboard-created, pre-enabled Mapbox location view with a
  runtime-owned map that is created only after a bounded public token passes
  validation.
- Added tested coordinate, style URL, token, authorization, freshness, future
  skew, horizontal-accuracy, and stale-callback policies, including null-island
  sentinel rejection.
- Deferred location permission until the configured map screen is visible,
  stopped tracking when it leaves, and added current authorization callbacks.
- Added 20 native Swift policy tests, nine hostile mutations, a supported Swift
  4/iOS 12 project baseline, and pinned macOS hosted Xcode verification.

## 2026-06-17

- Added validated local coordinate overrides for the map center and prize
  marker, preserving pairwise reviewed demo fallbacks for invalid settings.

## 2026-06-13

- Changed initial map setup to request location authorization only from the
  undetermined state and reuse the captured status for tracking setup.
- Kept Mapbox attribution and telemetry controls explicitly visible and removed
  the deprecated plist flag for a separate in-app metrics setting.

## 2026-06-12

- Made each location authorization transition consume its delegate-provided
  status and reset Mapbox follow mode after denial or revocation.
- Added a tracked-file guard for public and secret Mapbox token formats without
  exposing matched values in checker output.
- Rejected Mapbox style URL credentials, token query parameters, and incomplete
  Mapbox owner/style paths while preserving credential-free HTTPS providers.

## 2026-06-10

- Required scheme-appropriate authorities for locally configured Mapbox and
  HTTPS style URLs.
- Added a least-privilege GitHub Actions workflow that installs Ruby 3.3 and
  runs the static `make check` baseline with pinned Node 24-compatible actions
  and disabled checkout credential persistence.
- Added SHA-256 integrity coverage for the vendored Mapbox framework binary.
- Made legacy Xcode compilation explicit and fixed hosted validation to Ubuntu
  24.04 with concurrency cancellation.

## 2026-06-09

- Cleared the checked-in Xcode development team and added static validation so
  signing teams stay local.
- Restricted locally configured Mapbox style URLs to `mapbox` or `https`
  schemes, with static validation for the helper.
- Added optional local Mapbox style URL configuration and static checks that
  reject checked-in style URLs.
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
