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
- Keep annotation rendering safe when Mapbox supplies unexpected metadata
- Avoid committing Mapbox tokens or private style URLs
- Keep completed maintenance plans under `docs/plans`
- Treat Swift and CocoaPods versions as legacy until documented

Next priorities:

- Add README setup notes for Mapbox credentials and Xcode version
- Document whether coordinates are fixed, demo-only, or configurable
- Add a local configuration file template for map style/token values
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
- Broad app rewrites without preserving the proposal flow

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
