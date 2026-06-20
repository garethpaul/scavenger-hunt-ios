# Location Authorization Transitions

## Status: Completed

## Context

The location delegate receives the exact authorization status for each change,
but `ViewController` discards that value and rereads global state. The existing
helper also returns without clearing Mapbox follow mode when authorization is
denied, restricted, or revoked.

## Priority

User-location tracking should be a direct function of the delivered permission
transition. This is a privacy and correctness boundary that can be verified
statically without the archived Xcode toolchain.

## Requirements

- R1. Pass the delegate-provided `CLAuthorizationStatus` into the tracking
  helper without rereading global state inside the callback.
- R2. Enable Mapbox follow mode only for `.authorizedWhenInUse` and
  `.authorizedAlways`.
- R3. Reset Mapbox tracking to `.none` for every other authorization state.
- R4. Initialize tracking from the current authorization status after the map
  view is configured.
- R5. Preserve the when-in-use request, map configuration, and prize flow.
- R6. Protect the transition contract with focused hostile mutations and
  `make check`.

## Scope Boundaries

- Do not request always-on location access.
- Do not change prize coordinates, Mapbox style behavior, or map presentation.
- Do not claim simulator/device verification without a compatible Xcode host.

## Verification Plan

- `ruby scripts/check_ios_contract.rb`
- `make check`
- focused authorization-transition mutations
- `git diff --check`

## Work Completed

- Replaced the global-status reread helper with a status-driven tracking
  transition that receives `CLAuthorizationStatus` explicitly.
- Initialized tracking from the current status after map setup and passed the
  delegate-provided status directly on later changes.
- Enabled `.follow` only for authorized states and reset tracking to `.none`
  for denied, restricted, not-determined, or revoked access.
- Extended the static contract and project guidance for the transition rule.

## Verification

- `ruby scripts/check_ios_contract.rb` passed.
- `make check` passed with the legacy Xcode build skipped by documented policy.
- 11 focused hostile authorization-transition mutations were rejected with
  valid Git metadata.
- `git diff --check` passed.
- `swiftc` and `xcodebuild` were unavailable on this Linux host, so simulator
  compilation and runtime transition testing remain delegated to macOS.
