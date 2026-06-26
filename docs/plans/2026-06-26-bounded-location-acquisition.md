# Bounded Location Acquisition Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Stop a visible-screen location acquisition session after one 15-second deadline if no acceptable location arrives.

**Architecture:** Extend the pure generation coordinator with an explicit timeout transition, then add one cancellable main-queue work item to each `LocationAcquisitionSession`. Route timeout callbacks through both session identity and generation checks before stopping Core Location and Mapbox presentation.

**Tech Stack:** Swift 4, Core Location, Grand Central Dispatch, XCTest, Ruby source contracts, GNU Make

---

Status: Completed

### Task 1: Prove timeout ownership in the coordinator

**Files:**
- Modify: `PolicyTests/AppPolicyTests.swift`
- Modify: `Sources/ScavengerHuntPolicies/AppPolicy.swift`

1. Add failing tests requiring a current timeout to stop an awaiting generation
   and a stale timeout to leave the current generation active.
2. Run `swift test --disable-index-store` on macOS and confirm compilation fails
   because `handleOwnManagerTimeout(generation:)` is absent.
3. Add the minimal coordinator timeout transition.
4. Rerun the focused Swift tests and require green.

### Task 2: Bound the production acquisition session

**Files:**
- Modify: `scripts/check_ios_contract.rb`
- Modify: `engagement/ViewController.swift`

1. Add a failing static contract for the 15-second deadline, cancellation in
   `stop()`, timeout delegate callback, current-session identity, and explicit
   coordinator timeout transition.
2. Run `ruby scripts/check_ios_contract.rb` and confirm the new contract fails.
3. Add a cancellable `DispatchWorkItem` to `LocationAcquisitionSession` and a
   timeout delegate path in `ViewController`.
4. Rerun the Ruby contract and Swift tests.

### Task 3: Add hostile regressions and guidance

**Files:**
- Modify: `scripts/check_policy_mutations.rb`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `SECURITY.md`
- Modify: `VISION.md`
- Modify: `CHANGES.md`
- Modify: `docs/plans/2026-06-26-bounded-location-acquisition.md`

1. Add mutations for stale timeout ownership, omitted deadline cancellation,
   bypassed session identity, and ignored timeout cleanup.
2. Synchronize privacy, lifecycle, and energy guidance.
3. Run repository and external-working-directory `make check`, Ruby and shell
   syntax, `git diff --check`, and isolated hostile mutations.
4. Open a PR, run Codex review, require exact-head hosted checks and CodeQL,
   record evidence, and merge only the reviewed head.

## Verification Status

Implementation and focused source contracts are complete. `make check`, hosted
Swift policy/mutation tests, the legacy x86_64 build, and CodeQL remain required
before merge.

Local evidence: both repository-root and external-working-directory `make
check` passed in Ruby 3.3 with truthful macOS-only skips; five isolated timeout
mutations were rejected; Ruby and shell syntax plus `git diff --check` passed.
