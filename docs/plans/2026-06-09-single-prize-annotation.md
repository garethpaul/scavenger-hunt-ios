# Single Prize Annotation Guard

## Status: Completed

## Context

`scavenger-hunt-ios` adds the prize marker in `viewDidAppear`. That method can
run multiple times during the app lifecycle, so the map could accumulate
duplicate prize annotations after repeated appearances.

## Objectives

- Preserve the existing prize marker and custom pin behavior.
- Ensure the marker is added only once per view-controller lifecycle.
- Extend static verification so duplicate marker insertion is not reintroduced.

## Work Completed

- Added `didAddPrizeAnnotation` state to `ViewController`.
- Guarded `viewDidAppear` before creating and selecting the prize annotation.
- Extended `scripts/check_ios_contract.rb` to require the single-marker guard.
- Documented the behavior guard in README, VISION, and CHANGES.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `make verify`
- `git diff --check`

## Follow-Up Candidates

- Add simulator notes for verifying the prize marker after navigating away and
  returning when Xcode is available.
- Move the prize coordinate into a documented configuration value if the app is
  reused beyond the original proposal flow.
