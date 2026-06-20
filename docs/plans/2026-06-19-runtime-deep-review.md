# Runtime Deep Review

Status: Completed

## Scope

Deep-review the stacked pull requests `#2` through `#7` across local Mapbox
configuration, coordinates, location authorization and lifecycle, privacy
disclosure, attribution and telemetry controls, Xcode compatibility, workflow
permissions, tests, and historical credential handling.

## Root Causes

- The storyboard instantiated an `MGLMapView` with `showsUserLocation` enabled
  before runtime token validation or the controller's authorization gate.
- Runtime behavior depended on source-string checks rather than executable
  policies for token shape, URL bounds, coordinate sentinels, location freshness,
  accuracy, or stale callbacks.
- Permission was requested from `viewDidLoad`, before the configured map screen
  was visible, and tracking ownership was not invalidated on disappearance.
- The project remained pinned to unsupported Swift 3 defaults despite compiling
  in Swift 4 mode with a current Xcode toolchain.

Provenance: the early storyboard Mapbox view and checked-in token originated in
the initial December 2016 implementation. The June 2026 stacked fixes improved
static validation but carried the storyboard lifecycle and executable-test gap
forward. Confidence: clear from bounded Git history and the combined PR tip.

## Fix

- Create the map only after a bounded, public `pk.` token validates; never print
  credential values.
- Share executable policies for finite/ranged/non-sentinel coordinate pairs,
  bounded credential-free style URLs, fresh and accurate locations, and
  visible-screen authorization ownership.
- Remove the storyboard Mapbox instance, keep attribution and telemetry controls
  visible, and own the title logo through `navigationItem.titleView`.
- Defer when-in-use permission until `viewDidAppear`, support legacy and current
  authorization callbacks, reject stale-session callbacks, and stop tracking on
  disappearance or failure.
- Move the app to Swift 4 and iOS 12, preserving the vendored Mapbox 3.1.2
  dependency and its x86_64 simulator limitation.

## Verification

- `swift test`: 20 tests passed.
- `ruby scripts/check_policy_mutations.rb`: nine hostile mutations were rejected.
- `ruby scripts/check_ios_contract.rb`: passed.
- `make check`: passed on macOS.
- Unsigned x86_64 simulator `xcodebuild`: passed with Xcode 26.0.1.
- Root-independent `make check`: passed.
- Current-tree and full-history credential scans ran without printing values.
- Exact-head and post-merge GitHub Actions checks are required before completion.

## Residual Risk

- The vendored Mapbox 3.1.2 SDK owns tile/style networking, response parsing,
  telemetry, and provider failures; application code cannot impose response-body
  limits inside that binary.
- The old framework has no arm64 simulator slice, so simulator execution and
  native app-target XCTest are unavailable on Apple Silicon. Pure policy XCTest
  runs natively through Swift Package Manager instead.
- Physical GPS accuracy, permission changes, background suspension, telemetry
  opt-out, live provider responses, visual placement, and device signing remain
  manual checks.
- A historical Mapbox token remains a rotation/revocation action for the owner
  until provider evidence confirms it is disabled.

## Completion

The implementation, tests, documentation, and `make check` evidence are complete.
