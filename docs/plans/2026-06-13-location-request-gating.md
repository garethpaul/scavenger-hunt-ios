# Location Authorization Request Gating

## Status: Completed

## Context

`ViewController.viewDidLoad()` calls `requestWhenInUseAuthorization()` on every
load before reading the current location authorization status. The existing
status-driven tracking helper already handles authorized, denied, restricted,
and revoked states, but permission requests are not limited to the initial
undetermined state.

## Priority

Location permission prompts should be initiated only when the user has not yet
made a choice. Existing denied or restricted decisions should flow directly to
tracking-disabled behavior without another request attempt.

## Objectives

- Read the current authorization status once during map setup.
- Request when-in-use authorization only for `.notDetermined`.
- Apply the same status immediately through `updateUserTracking(for:)`.
- Preserve delegate-driven transitions after the initial setup.
- Add fail-closed static and mutation coverage within the Linux validation
  boundary.

## Implementation Units

### U1. Gate the initial authorization request

**Goal:** Separate initial prompt eligibility from tracking-state application.

**Files:** `engagement/ViewController.swift`

**Approach:** Store the current status, request permission only when it equals
`.notDetermined`, and pass the captured status to the existing tracking helper
after map initialization.

**Verification:** The source contains no unconditional authorization request,
and authorized, denied, restricted, and revoked tracking behavior is unchanged.

### U2. Protect lifecycle ordering

**Goal:** Keep request gating and status application reviewable and mutation
sensitive.

**Dependencies:** U1

**Files:** `scripts/check_ios_contract.rb`

**Approach:** Require one captured status, one `.notDetermined` guard, one
request call inside that guard, and initial tracking driven by the captured
status rather than a second global reread.

**Verification:** Focused unconditional-request, wrong-status, duplicate-read,
missing-update, documentation, and completed-plan mutations are rejected.

### U3. Synchronize privacy evidence

**Goal:** Keep maintenance documentation aligned with prompt gating.

**Dependencies:** U1, U2

**Files:** `README.md`, `VISION.md`, `SECURITY.md`, `CHANGES.md`,
`docs/plans/2026-06-13-location-request-gating.md`

**Approach:** Document that initial permission requests are limited to the
undetermined state and record actual static validation evidence.

**Verification:** `make check` passes with only the documented legacy Xcode
skip, plus focused hostile mutations and structured artifact checks.

## Scope Boundary

This change does not alter permission copy, request background location,
introduce a settings deep link, or claim simulator/device validation.

## Work Completed

- Captured the initial `CLLocationManager` authorization status once after
  assigning the delegate.
- Limited `requestWhenInUseAuthorization()` to `.notDetermined` and reused the
  captured status for initial tracking setup.
- Extended the static iOS contract and maintained documentation to preserve the
  request boundary and status ordering.

## Verification

- `ruby scripts/check_ios_contract.rb` passed.
- `make check` passed with only the documented legacy Xcode build skip because
  no compatible Apple toolchain is installed in the Linux environment.
- Focused hostile mutations rejected unconditional requests, the wrong status,
  delegate ordering loss, duplicate status reads, missing captured-status
  application, documentation drift, and an incomplete plan status.
- Root-independent validation and structured workflow, plist, asset JSON, and
  README SVG parsing passed.
