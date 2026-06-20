## Scavenger Hunt iOS Vision

Scavenger Hunt iOS is a small Swift proposal app that centers a Mapbox map,
shows custom branding, and marks a prize location.

The repository is useful as a focused personal-map prototype with location,
annotation, and custom map-style setup.

The goal is to preserve the app's narrative and map interaction while making
location, token, and toolchain assumptions explicit.

The current focus is:

Priority:

- Preserve the proposal/scavenger-hunt map flow
- Keep the prize annotation and custom pin behavior understandable
- Keep the prize marker from duplicating across repeated view appearances
- Keep annotation rendering safe when Mapbox supplies unexpected metadata
- Avoid committing Mapbox tokens or private style URLs
- Keep optional Mapbox style URLs in local configuration
- Keep configured Mapbox style URLs limited to expected schemes
- Keep configured style URLs bound to valid scheme-specific authorities
- Keep Mapbox style URL credentials and token query parameters out of style
  configuration, with complete owner/style paths for Mapbox-scheme URLs
- Request visible location authorization before user-location tracking
- Keep location authorization scoped to when-in-use foreground tracking
- Enable Mapbox user tracking only after compatible authorization is available
- Keep each location authorization transition status-driven and revoke follow
  mode when permission becomes unavailable
- Keep initial setup able to request location authorization only from the
  undetermined state
- Keep validated local coordinate overrides pairwise and preserve reviewed demo
  fallbacks when local event values are incomplete or invalid
- Reject non-finite, out-of-range, and exact null-island sentinel coordinates
- Accept location samples only while the map screen owns an active foreground
  request and only when freshness and accuracy bounds pass
- Avoid logging precise user coordinates
- Keep Xcode workspace and scheme metadata portable across machines
- Keep account-specific Xcode signing teams out of source control
- Keep completed maintenance plans under `docs/plans`
- Keep GitHub Actions running static, native Swift policy, mutation, and Xcode
  build gates
- Keep the vendored Mapbox framework covered by a reviewed SHA-256 digest
- Reject public and secret Mapbox token formats from tracked non-vendored files
- Keep Mapbox attribution and telemetry controls visible on the map
- Keep the Swift 4/iOS 12 source baseline buildable while the vendored Mapbox
  framework remains limited to legacy device and x86_64 simulator slices

Next priorities:

- Add README setup notes for Mapbox credentials and Xcode version
- Include simulator verification notes for annotation behavior

Contribution rules:

- One PR = one focused map, location, UI, dependency, or documentation change.
- Do not commit private coordinates beyond intentional demo markers.
- Keep map credentials out of source control.
- Include screenshots or manual verification for visual changes.

## Security And Responsible Use

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Scavenger-hunt apps can expose private places and location history. The app
should keep coordinates intentional, avoid uploading location data, and make
user tracking behavior visible.

## What We Will Not Merge (For Now)

- Checked-in Mapbox credentials
- Silent user-location upload
- Unexplained private-location changes
- Duplicate map markers that obscure the intended proposal flow
- Broad app rewrites without preserving the proposal flow

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
