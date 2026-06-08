# Location Log Privacy

## Status: Completed

## Context

`scavenger-hunt-ios` requests when-in-use location authorization and uses
Mapbox user-location tracking. The location delegate still printed precise
latitude and longitude values to stdout whenever location updates arrived.
Those logs are unnecessary for the sample flow and can expose private user
coordinates during local debugging or shared logs.

## Objectives

- Stop logging precise user coordinates from the location callback.
- Preserve the location authorization and Mapbox tracking setup.
- Extend static verification so precise coordinate logging is not reintroduced.
- Keep verification useful when Xcode is unavailable.

## Work Completed

- Removed latitude/longitude printing from `locationManager(_:didUpdateLocations:)`.
- Extended `scripts/check_ios_contract.rb` to reject precise coordinate logs.
- Updated README, VISION, and CHANGES notes for the privacy guard.

## Verification

- `ruby scripts/check_ios_contract.rb`
- `make check`
- `make verify`
- `git diff --check`
