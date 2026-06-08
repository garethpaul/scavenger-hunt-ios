# Location Authorization Guard

## Status: Completed

## Context

`scavenger-hunt-ios` shows the user's location on a Mapbox map and sets user
tracking mode to follow. The app had a when-in-use usage string in
`Info.plist`, but the view controller did not explicitly request when-in-use
authorization before enabling the map flow.

## Objectives

- Keep the existing Mapbox map and annotation behavior intact.
- Request when-in-use location authorization from the view controller.
- Extend static verification so the permission request is not removed
  accidentally.
- Document the location-permission guard in the project maintenance notes.

## Work Completed

- Set the location manager delegate and requested when-in-use authorization in
  `ViewController.viewDidLoad()`.
- Extended `scripts/check_ios_contract.rb` to require the location permission
  handshake.
- Updated README, VISION, and CHANGES.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `make verify`
- `git diff --check`

## Follow-Up Candidates

- Add simulator verification notes for the permission prompt and map tracking
  behavior when Xcode is available.
- Move demo coordinates into a clearly named local or documented configuration
  value if the app is reused beyond the original proposal flow.
