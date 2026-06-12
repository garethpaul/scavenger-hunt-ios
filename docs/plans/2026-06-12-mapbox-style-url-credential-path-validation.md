# Mapbox Style URL Credential And Path Validation

## Status: Completed

## Context

The archived app resolves an optional Mapbox style URL from local build
configuration and already restricts it to `mapbox` or `https` with a valid
authority. The helper still accepts embedded URL user information, explicit
`access_token` query parameters, and incomplete values such as
`mapbox://styles` without owner and style path components.

## Priority

Style URLs cross a network and credential boundary. The dedicated
`MGLMapboxAccessToken` configuration should remain the only token channel, and
accepted `mapbox://styles/...` values should identify a usable owner/style
resource. These checks are local parsing changes and do not require reviving
the legacy Mapbox or Xcode runtime.

## Requirements

- R1. Reject configured style URLs containing a username or password.
- R2. Reject style URL queries containing an `access_token` parameter without
  logging or exposing the value.
- R3. Require `mapbox://styles/<owner>/<style>` to contain at least two
  non-root path components.
- R4. Preserve credential-free custom HTTPS style URLs with non-empty hosts.
- R5. Preserve blank or unresolved configuration as default-style behavior.
- R6. Extend the dependency-free checker and project documentation to keep the
  credential and Mapbox path contracts fail closed.
- R7. Protect user info, token queries, incomplete paths, accepted HTTPS URLs,
  documentation, and plan completion with focused hostile mutations.

## Scope Boundaries

- Do not change the separately configured Mapbox access-token mechanism.
- Do not log rejected URLs or credential values.
- Do not restrict HTTPS styles to Mapbox-owned hosts; documented custom style
  providers remain supported.
- Do not rewrite history or dismiss the existing secret-scanning alert without
  credential-owner revocation evidence.
- Do not claim modern Mapbox or Xcode compatibility.

## Verification Plan

- `ruby scripts/check_ios_contract.rb`
- `make check` locally, outside the checkout, and in a network-isolated Ruby
  container
- focused valid-Git-metadata mutations for every new URL boundary
- workflow YAML, plist, asset JSON, SVG XML, and vendored-framework digest checks
- Swift delimiter/source checks, secret screening, and `git diff --check`

## Work Completed

- Rejected style URLs containing URL usernames or passwords before Mapbox map
  initialization.
- Parsed URL query items and rejected case-insensitive `access_token` names so
  the separate plist token setting remains the only supported credential path.
- Required Mapbox-scheme style URLs to contain at least owner and style path
  components after the `styles` authority.
- Preserved credential-free custom HTTPS providers with non-empty hosts and the
  existing blank/unresolved default-style behavior.
- Extended the dependency-free checker, local configuration template, README,
  security guidance, vision, and changelog with the new boundary.

## Verification

- `ruby scripts/check_ios_contract.rb` passed after implementation.
- `make check` and root-independent `make -f /path/to/Makefile check` passed;
  both reported the documented legacy Xcode skip because no compatible macOS
  toolchain is installed.
- A read-only, network-isolated Ruby 3.3 container at
  `ruby@sha256:c5601aff6552fa869f3c09a4a804f284b5f46762af7de0d210f2f7081e0e9e96`
  passed `make check` against an exact standalone Git snapshot.
- Eleven focused valid-Git-metadata mutations were rejected: missing or partial
  URL user-info checks, missing/case-sensitive/wrong token query checks,
  missing or incomplete Mapbox paths, weakened HTTPS host and scheme controls,
  missing security guidance, and incomplete-plan status.
- Workflow YAML, three plists, seven asset JSON files, and two README SVG files
  parsed successfully.
- The vendored Mapbox executable matched `VENDORED_FRAMEWORKS.sha256`.
- Swift delimiter checks, corrected PCRE2 high-confidence secret and Mapbox
  token screening, and `git diff --check` passed.
- Legacy Xcode compile, simulator, and device validation remain unavailable in
  this Linux environment.
