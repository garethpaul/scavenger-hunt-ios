# Mapbox Secret Token Guard

## Status: Completed

## Context

GitHub secret scanning retains one open historical Mapbox secret-token alert at
commit `cd55b858f1326c9d6f7952dada0bde68ae0f78a6`. The current tree uses local
build-setting placeholders, but the repository contract only recognizes the
`pk.` public-token prefix in `Info.plist` and does not protect other tracked
source or configuration files from `sk.` secret-token reintroduction.

## Priority

The historical token cannot be revoked or validated from source control, but
the current branch can fail closed on both Mapbox token formats everywhere
outside the preserved vendored dependency tree.

## Requirements

- R1. Scan every tracked non-vendored file for Mapbox `pk.` and `sk.` token
  formats without printing matched secret material.
- R2. Keep local placeholder configuration valid.
- R3. Report only the offending path when a token is detected.
- R4. Preserve the historical alert as an explicit remaining risk until the
  credential owner confirms revocation and resolves it in GitHub.
- R5. Protect the guard, documentation, and completed plan with focused hostile
  mutations and `make check`.

## Scope Boundaries

- Do not retrieve, print, or reuse the historical secret value.
- Do not rewrite Git history.
- Do not mark the GitHub alert resolved without credential-owner evidence.

## Verification Plan

- `ruby scripts/check_ios_contract.rb`
- `make check`
- focused public-token and secret-token mutations
- `git diff --check`

## Work Completed

- Added a tracked-file scan for Mapbox `pk.` and `sk.` token formats while
  excluding the preserved vendored CocoaPods tree.
- Kept checker failures path-only so matched token values are never printed.
- Added self-sentinels for prefix coverage, tracked-file enumeration, vendored
  exclusion, binary-safe reads, matching, and value-free reporting.
- Documented the still-open historical alert and credential-owner revocation
  boundary across the repository guidance.

## Verification

- `ruby scripts/check_ios_contract.rb` and `make check` passed.
- Eight focused hostile mutations were rejected with valid Git metadata.
- Fake public and secret token values were not echoed in checker output.
- `git diff --check` passed.
- GitHub alert 1 remains open with unknown validity; no resolution claim was
  made because credential revocation cannot be verified from this repository.
