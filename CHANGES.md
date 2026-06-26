# Changes

## 2026-06-26 - P2 - Bound visible-screen location acquisition

### Summary

Visible-screen location acquisition stops after one 15-second deadline when no
acceptable fix arrives, preventing repeated recoverable errors or rejected
samples from leaving continuous Core Location updates active indefinitely.

### Work completed

- Added a cancellable per-session deadline before continuous location updates.
- Added a generation-aware timeout transition and current-session identity gate.
- Added policy tests for current and stale timeout generations plus hostile
  source mutations for cancellation, identity, and presentation cleanup.
- Preserved when-in-use authorization, accepted-sample handoff, coordinate
  privacy, recoverable Mapbox behavior, and view-disappearance cleanup.

### Validation

- Focused RED/GREEN source contracts passed in the official Ruby 3.3 container.
- Ruby syntax checks passed for the static and mutation contracts.
- Repository-root and external-working-directory `make check` passed with
  truthful Linux skips for Apple-only execution.
- Five isolated timeout mutations were rejected locally.
- Exact implementation head `5fff48323beabe383dfbdce3f3d2d669d16dd617`
  passed Ubuntu static checks, 29 Swift tests, 22 policy mutations, 11 location
  integration mutations, the unsigned x86_64 Xcode build, and CodeQL Actions
  plus Ruby analysis.
- Codex review failed with OpenAI HTTP 401 before analysis; immutable manual
  review found no correctness, privacy, lifecycle, or compatibility findings.

### Files changed

- `Sources/ScavengerHuntPolicies/AppPolicy.swift`
- `PolicyTests/AppPolicyTests.swift`
- `engagement/ViewController.swift`
- `scripts/check_ios_contract.rb`
- `scripts/check_policy_mutations.rb`
- repository guidance and implementation/design plans

### Blockers

- This Linux host has no native Ruby installation or Apple Core Location/Xcode
  runtime; Ruby runs in the official container and Apple validation remains a
  hosted exact-head requirement.

## 2026-06-26 05:53 - P2 - Document legacy Mapbox setup and verification

### Summary

Closed the two remaining setup-documentation roadmap items with metadata-backed
credential, workspace, toolchain, simulator, device, and privacy guidance.

### Work completed

- Documented the Swift 4/iOS 12 app baseline, Mapbox 3.1.2 and CocoaPods 1.1.1
  lock provenance, local public-token configuration, and local signing ownership.
- Corrected the run entry point from the bare project to `engagement.xcworkspace`.
- Added an exact-commit simulator/device verification matrix with every runtime
  row explicitly `not run`.
- Added Ruby contracts for the guide, matrix, completed roadmap state, and plan.

### Threads

- Started: none; the bounded documentation change was completed directly.
- Continued: continuous open-source maintenance loop.
- Stopped: none.

### Files changed

- `README.md` — legacy setup and simulator/device evidence boundaries.
- `DEVICE_VERIFICATION.md` — privacy-safe exact-commit verification matrix.
- `VISION.md` — removed completed setup-guide priorities.
- `scripts/check_ios_contract.rb` — durable documentation contracts.
- `docs/plans/2026-06-25-mapbox-legacy-setup-guide.md` — implementation and verification plan.
- `CHANGES.md` — this maintenance-cycle record.

### Validation

- `make root-test` — passed after the documentation and contract edits.
- `make check` in the official Ruby 3.3 container — passed; Linux correctly
  skipped macOS-only Swift policy, mutation, and Xcode execution.
- Eight isolated hostile documentation mutations — all rejected after tightening
  the obsolete-project instruction and exact matrix-link assertions.
- Manual metadata review — passed for Xcode project, Podfile lock, secrets template, workspace, and framework slices.

### Bugs / findings

- P2: README incorrectly instructed maintainers to open the bare Xcode project
  despite the CocoaPods workspace being the supported build entry point.
- P2: Setup text lacked the framework's no-arm64-simulator boundary and could
  lead maintainers to misclassify Apple Silicon simulator failures.
- P2: Initial documentation contracts accepted an obsolete bare-project
  instruction and a renamed matrix link when equivalent text existed elsewhere;
  isolated mutations exposed both weaknesses before publication.

### Blockers

- Local Swift, Xcode, simulator, and physical-device execution are unavailable;
  Ruby validation is available through the official Ruby 3.3 container.

### Next action

- Run exact-head hosted static, Swift policy, mutation, and x86_64 Xcode gates;
  then review and merge if clean.

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
