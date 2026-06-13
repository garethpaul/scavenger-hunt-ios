# Mapbox Attribution And Telemetry Controls

## Status: Completed

## Context

The vendored Mapbox SDK documents its attribution button as the surface for
legally required notices and telemetry settings. The app did not explicitly
preserve that button or the Mapbox logo, while `Info.plist` retained the
deprecated `MGLMapboxMetricsEnabledSettingShownInApp` flag even though the same
SDK states that telemetry settings are always shown in the information menu.

## Priority

Attribution and telemetry choice are user-facing privacy and compliance
boundaries. The archived app should preserve the controls supplied by its
vendored SDK and avoid a stale configuration key that implies a separate app
setting exists.

## Objectives

- Keep the Mapbox logo visible after programmatic map construction.
- Keep the attribution button and its telemetry settings visible.
- Remove the deprecated metrics-setting plist flag.
- Reject source changes that hide, remove, or make either control transparent.
- Add fail-closed documentation and completed-plan contracts.
- Preserve map style, location authorization, annotation, and layout behavior.

## Work Completed

- Explicitly kept the Mapbox logo and attribution button visible during map
  setup.
- Removed `MGLMapboxMetricsEnabledSettingShownInApp` from the app plist.
- Extended the dependency-free iOS checker to require both controls, reject
  common hiding/removal patterns, and preserve the documentation contract.
- Updated README, security, vision, and changelog guidance.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check` locally and from outside the repository root
- focused logo, attribution, opacity, removal, deprecated-plist, documentation,
  and plan mutations
- workflow YAML, plist, asset JSON, README SVG, vendored-framework digest,
  Swift delimiter, secret, artifact, and `git diff --check` audits
- document the unavailable legacy Xcode/simulator/device boundary

The iOS contract checker and full `make check` passed locally and through a
root-independent Make invocation. The exact locally available Ruby 3.3 image
digest also passed `make check` with a read-only checkout and disabled
networking. All eight focused missing-control, hidden-control, opacity,
removal, deprecated-plist, documentation, and plan-status mutation categories
were rejected.

The workflow YAML, three plists, seven asset JSON files, and both README SVG
files parsed successfully. The vendored Mapbox executable matched
`VENDORED_FRAMEWORKS.sha256`; Swift delimiter, high-confidence secret,
generated-artifact, and `git diff --check` audits passed. Existing trailing
whitespace on untouched legacy Swift lines was preserved. `xcodebuild` and
`swiftc` are unavailable, so compile, simulator, and device validation remain
delegated to a compatible macOS toolchain.

## Scope Boundary

This preserves the telemetry choice exposed by the vendored Mapbox SDK. It
does not update the historical binary, change telemetry defaults, resolve the
owner-only historical secret alert, or claim current App Store compliance.
