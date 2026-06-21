# Make Root Override Protection

## Status: Completed

## Context

The Makefile derives its repository root from the loaded file and uses that
path for static iOS validation and optional legacy Xcode execution. GNU Make
command-line variables outrank an ordinary assignment, so `make ROOT=/tmp
check` can redirect those gates away from the checkout.

## Requirements

- **R1:** Prevent command-line and environment values from replacing the
  Makefile-derived repository root.
- **R2:** Keep `RUN_LEGACY_XCODE` configurable. Ruby was subsequently fixed by
  the Make authority-isolation follow-up because it is part of the
  repository-owned verification boundary.
- **R3:** Require the exact protected declaration in the iOS checker.
- **R4:** Prove every public Make alias from the checkout and an external
  directory with a hostile `ROOT` argument.
- **R5:** Preserve Mapbox credential, attribution, telemetry, vendored-framework,
  signing, location, and hosted-workflow contracts.

## Implementation Units

### U1. Protected Root

Give the repository-derived root override precedence without changing recipes,
runtime selection, or the legacy Xcode opt-in.

### U2. iOS Contract

Extend `scripts/check_ios_contract.rb` to reject weakened, duplicate,
displaced, or caller-controlled root declarations and incomplete evidence.

### U3. Verification

Run the static contract, all Make aliases, external hostile execution, Ruby
3.3 validation, mutations, and integrity screening.

## Scope Boundary

- Do not modify Swift, projects, workspace, schemes, Pods, or signing settings.
- Do not change location, attribution, telemetry, or Mapbox style behavior.
- Do not add tokens, build outputs, caches, or dependency changes.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- external `make ROOT=/tmp check`
- root-declaration, checker, plan-status, README-index, and evidence mutations
- Ruby syntax, workflow YAML, protected-file, secret, artifact, and
  `git diff --check` gates

## Work Completed

- Protected the Makefile-derived repository root from command-line and
  environment overrides while preserving configurable Ruby and Xcode inputs.
- Added exact declaration, completed-evidence, and README-index contracts.
- Preserved all Swift, Mapbox, signing, location, vendored-framework, and
  workflow behavior boundaries.

## Verification Results

- `ruby scripts/check_ios_contract.rb` passed.
- From both the checkout and an external directory, all five public Make aliases passed.
- `make ROOT=/tmp check` passed externally while still executing the
  repository-owned iOS contract.
- Ruby 3.3 passed the full static gate; legacy Xcode remained explicitly
  skipped because `RUN_LEGACY_XCODE` was not enabled on a compatible macOS host.
- Six hostile mutations were rejected across root declaration, checker
  expectation, plan status, README indexing, and recorded evidence.
- Ruby syntax, workflow YAML, exact-base protected-file comparison, secret
  screening, generated-artifact screening, and `git diff --check` passed before
  shipping.
