# Mapbox Legacy Setup Guide Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Close the roadmap gaps for Mapbox credential setup, legacy Xcode requirements, and simulator verification evidence.

**Architecture:** Keep runtime and project files unchanged. Document facts from the checked-in Xcode project, Podfile lock, secrets template, framework slices, and existing verification commands; enforce the guidance through the Ruby contract.

**Tech Stack:** Markdown, Ruby static contracts, CocoaPods metadata, Xcode project metadata

---

Status: Completed

### Task 1: Add the maintainer guide

**Files:**
- Modify: `README.md`
- Create: `DEVICE_VERIFICATION.md`

1. Document Swift 4, iOS 12, Mapbox 3.1.2, CocoaPods 1.1.1 provenance, local public-token setup, local signing, and workspace use.
2. Explain that the vendored framework has x86_64/i386 simulator and armv7/armv7s/arm64 device slices but no arm64 simulator slice.
3. Add an exact-commit matrix with static, policy, Intel simulator, Apple Silicon, and physical-device evidence rows.
4. Keep all runtime rows explicitly `not run` until executed.

### Task 2: Add durable contracts

**Files:**
- Modify: `scripts/check_ios_contract.rb`
- Modify: `VISION.md`
- Modify: `CHANGES.md`

1. Require the guide facts and exact-commit matrix.
2. Remove the completed roadmap items.
3. Record the cycle, local tool limitations, files, validation, blockers, and next action.

### Task 3: Validate and publish

**Files:**
- Modify: this plan

1. Run `make root-test`, Ruby syntax, the Ruby contract where Ruby is available, shell syntax, and `git diff --check`.
2. Open a PR and require exact-head Ubuntu static checks, macOS Swift policy tests, mutation tests, and x86_64 Xcode build.
3. Run Codex review, verify findings manually, and merge only with clean exact-head evidence.

## Verification

- `make root-test` passed with 104 target/authority cases and the repository's
  preload, multi-Makefile, inert-data, and dollar-path boundary cases.
- `make check` passed in the official Ruby 3.3 container; Linux skipped the
  macOS-only Swift policy, mutation, and legacy Xcode gates as designed.
- Eight isolated hostile documentation mutations were rejected, including the
  obsolete bare-project instruction, exact matrix link, toolchain facts,
  simulator-slice boundary, exact-commit rule, and completed roadmap state.
- No token, style URL, signing team, coordinate, source, project, dependency, asset, or workflow behavior changes in this documentation pass.
- Simulator launch, physical-device location behavior, and signing remain explicit manual evidence boundaries.
