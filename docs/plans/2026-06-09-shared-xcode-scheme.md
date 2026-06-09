# Shared Xcode Scheme

## Status: Completed

## Context

`make check` can run an Xcode build when `xcodebuild` is available, but the
workspace referenced the project through a developer-local `/Users/gpj/...`
path and the app scheme was tracked under `xcuserdata`. That made command-line
builds depend on one workstation's user state.

## Objectives

- Keep the workspace reference relative to the repository.
- Provide a shared `engagement` scheme for command-line and team builds.
- Remove tracked Xcode user state that `.gitignore` already treats as local.
- Add static verification so local-only scheme state is not recommitted.

## Work Completed

- Updated `engagement.xcworkspace/contents.xcworkspacedata` to reference
  `TreasureHunt.xcodeproj` relative to the workspace.
- Added `TreasureHunt.xcodeproj/xcshareddata/xcschemes/engagement.xcscheme`.
- Removed tracked `TreasureHunt.xcodeproj/xcuserdata` scheme files.
- Extended `scripts/check_ios_contract.rb` to reject absolute workspace paths,
  missing shared schemes, and tracked Xcode user state.
- Updated README, VISION, and CHANGES.

## Verification

- Negative: `ruby scripts/check_ios_contract.rb` failed before the Xcode file
  changes because the workspace used a developer-local path, no shared scheme
  existed, and `xcuserdata` files were tracked.
- `ruby scripts/check_ios_contract.rb`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

This environment does not provide `xcodebuild`, so the repository wrapper
reported the compile check as unavailable. The shared scheme is now present for
macOS workstations that do have Xcode installed.
