# Make Authority Isolation

## Status: Completed

## Context

The protected repository root stopped direct `ROOT=/tmp` redirection, but GNU
Make still accepted caller-controlled preload files, file lists, recipe shells,
Ruby and Swift commands, and Swift test flags. On macOS those channels could
bypass or replace the static, policy, mutation, and Xcode verification gates.

## Requirements

- **R1:** Load the repository Makefile alone and reject overridden file lists.
- **R2:** Derive the checkout root safely from the exact Makefile path.
- **R3:** Fix the shell, shell flags, Ruby, Swift, and Swift test flags.
- **R4:** Keep Xcode opt-in and derived-data paths configurable as inert data.
- **R5:** Exercise every public target across hostile authority inputs.

## Implementation

- Hardened Make authority before target recipes can run and added deferred
  validation after every Makefile has been parsed.
- Added a macOS-simulating `root-test` checkout with spaces, quotes, and
  command-substitution syntax in its path.
- Covered all eight public targets across thirteen authority modes, two inert
  Xcode configuration cases, and explicit file-list, preload, and preceding and
  trailing multiple-Makefile rejection cases.
- Left Swift, Xcode project, CocoaPods, Mapbox, and application behavior intact.
- Kept Ruby and Swift discovery on the provisioned `PATH`; local callers must
  treat that path as trusted. Xcode remains the fixed `/usr/bin/xcodebuild` host tool.
- Recorded the GNU Make startup boundary: a `MAKEFILES` preload is parsed before
  this Makefile can reject it, so the guard prevents repository recipes but
  cannot undo preload side effects.
- Added a literal `$()` checkout-path probe that verifies the apparent command
  substitution never executes across platform-specific GNU Make path handling.

## Verification

- `make root-test` passed 104 target/authority cases, two inert configuration
  cases, a detected preload startup, and five explicit rejection cases.
- The literal `$()` checkout-path case did not create its marker.
- `make check` passed from the repository and through an absolute Makefile path.
- Ruby and shell syntax checks, `git diff --check`, and repository integrity
  screening passed.
