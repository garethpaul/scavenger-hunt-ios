# Configurable Demo Coordinates

## Status: Completed

## Context

`ViewController` embeds the map center and prize location directly in source.
Those coordinates are intentional demo values, but the current code does not
name that boundary or provide a credential-free local configuration path for a
different scavenger hunt. Changing the location currently requires editing and
potentially committing source code.

## Priority

P1 privacy and reuse. Location values can describe a private event or proposal.
The repository should keep reviewed public demo fallbacks while allowing local
build configuration to replace them without source changes or silent invalid
coordinates.

## Objectives

- Preserve the existing map center and prize marker as explicit demo fallbacks.
- Read optional map-center and prize latitude/longitude pairs from Info.plist
  build-setting placeholders.
- Accept an override only when both components are present, resolved, numeric,
  finite, and form a valid Core Location coordinate.
- Fall back as a pair when either component is absent or invalid so values from
  different locations cannot be combined.
- Keep coordinate values out of logs and keep Mapbox credential handling
  unchanged.
- Add fail-closed static and mutation coverage within the Linux validation
  boundary.

## Implementation Units

### U1. Add validated coordinate resolution

**Goal:** Separate reviewed demo coordinates from optional local event values.

**Files:** `engagement/ViewController.swift`

**Approach:** Define named demo map-center and prize coordinates. Add one helper
that reads a latitude/longitude key pair from the application bundle, rejects
unresolved build placeholders and non-numeric values, validates the combined
coordinate with Core Location, and otherwise returns the supplied fallback.
Use the resolved map center during map setup and the resolved prize coordinate
when adding the annotation.

**Verification:** Existing fallback values remain exact, override resolution is
pairwise, invalid input cannot produce a coordinate, and no coordinate is
logged.

### U2. Declare local build-setting placeholders

**Goal:** Provide a source-controlled configuration boundary without storing a
private event location.

**Dependencies:** U1

**Files:** `engagement/Info.plist`, `engagement/MapboxSecrets.xcconfig.example`

**Approach:** Add map-center and prize latitude/longitude keys backed by Xcode
build-setting placeholders, and expose blank local settings in the existing
example configuration. Unconfigured placeholders intentionally reach the
resolver and select the reviewed demo fallbacks.

**Verification:** The plist remains valid and contains all four exact keys with
no real private coordinate values.

### U3. Protect the coordinate contract

**Goal:** Make privacy and validation behavior mutation-sensitive.

**Dependencies:** U1, U2

**Files:** `scripts/check_ios_contract.rb`

**Approach:** Require named demo fallbacks, pairwise bundle lookup, unresolved
placeholder rejection, numeric conversion, Core Location validity checking,
both call sites, all four plist placeholders, documentation, and completed-plan
evidence.

**Verification:** Focused mutations that remove a key, swap a call site, accept
partial/unresolved input, skip coordinate validation, change a fallback, weaken
guidance, or falsify completion are rejected.

### U4. Synchronize privacy and setup guidance

**Goal:** Make the demo-versus-local location boundary explicit to maintainers.

**Dependencies:** U1, U2, U3

**Files:** `README.md`, `VISION.md`, `SECURITY.md`, `CHANGES.md`,
`docs/plans/2026-06-17-configurable-demo-coordinates.md`

**Approach:** Document the four optional build settings, pairwise validation,
reviewed demo fallback behavior, and the rule against committing private event
coordinates.

**Verification:** `make check` passes from the repository and an external
directory, and documentation contracts fail closed when the boundary drifts.

## Scope Boundary

- Do not change the visible default map position or prize marker.
- Do not add a settings UI, location upload, reverse geocoding, persistence, or
  remote configuration.
- Do not alter Mapbox token/style configuration, Pods, project signing, or
  dependency versions.
- Do not claim Xcode, simulator, or device validation from Linux.
- Keep PR #6 and its predecessors open and preserve base-first stack ordering.

## Risks

- Legacy Swift syntax must remain compatible with the checked-in project era.
- Parsing one valid component with one invalid component would create an
  unintended hybrid location; resolution must be all-or-fallback.
- Build-setting placeholders are strings at runtime and must not be mistaken
  for configured coordinate values.

## Work Completed

- Replaced anonymous inline coordinates with named reviewed demo map-center and
  prize fallbacks while preserving their exact values.
- Added pairwise local build-setting resolution for map-center and prize
  latitude/longitude values, rejecting absent, unresolved, non-string,
  non-numeric, non-finite, and out-of-range inputs through Core Location
  validity checks.
- Added all four Info.plist placeholders and blank settings to the ignored local
  configuration example without committing a private event location.
- Extended the static checker and documentation to protect the privacy,
  configuration, provider-disclosure, and completed-plan boundaries.

## Verification

- The focused coordinate contract passed, including Ruby syntax and structured
  Info.plist parsing.
- Repository and external-directory make check passed with only the documented
  legacy Xcode build skip on Linux.
- Nine hostile coordinate mutations were rejected across plist and example
  keys, demo values, pairwise lookup, unresolved and non-numeric input,
  Core Location validity, call-site wiring, and documentation.
- Structured correctness, privacy, testing, maintainability, and project-policy
  review found and resolved boolean plist coercion and an overstated provider
  privacy claim; no actionable findings remain.
- Exact diff, generated-artifact, credential, conflict, mode, binary,
  dependency, vendored-framework, and upstream audits passed for the nine
  intended paths.
- A compatible Swift/Xcode toolchain is unavailable on Linux, so no compilation,
  simulator, device, or visual-behavior result is claimed.
