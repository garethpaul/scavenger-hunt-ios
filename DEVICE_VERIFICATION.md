# Scavenger Hunt iOS Verification Matrix

Use this matrix for one exact implementation commit. Record the commit and pull
request before testing; do not transfer build, simulator, permission, location,
annotation, or visual evidence between revisions.

## Privacy And Credential Rules

- Use only a locally configured public `pk.` Mapbox token. Never commit or paste
  a token, private style URL, signing identity, provisioning profile, or private
  event coordinate into this repository or verification notes.
- Use the reviewed demo coordinates or a synthetic public test location. Keep
  homes, workplaces, routes, device identifiers, and precise personal location
  out of screenshots and logs.
- Store durable screenshots or logs outside git and reference only a sanitized
  evidence identifier.
- Record every row as `pass`, `fail`, `blocked`, or `not run`. A build result is
  not location, annotation, or visual evidence.

## Build And Runtime Boundaries

- Build `engagement.xcworkspace`, not the bare project, from the same exact
  commit recorded below.
- The checked-in app target uses Swift 4 and iOS 12.0. `Podfile.lock` pins
  Mapbox iOS SDK 3.1.2 and records CocoaPods 1.1.1 provenance.
- The vendored Mapbox binary contains x86_64 and i386 simulator slices plus
  armv7, armv7s, and arm64 device slices. It does not contain an arm64 simulator
  slice, so Apple Silicon simulator execution requires an Intel-compatible
  environment; do not report an arm64 simulator result as supported.
- A simulator can establish build, launch, local configuration, annotation,
  callout, and static control behavior. Real authorization transitions, GPS
  accuracy, device signing, and physical-location behavior require a device.

## Run Identity

| Field | Value |
| --- | --- |
| Commit SHA | `not run` |
| Pull request | `not run` |
| Xcode / macOS | `not run` |
| CocoaPods | `not run` |
| Simulator or device | `not run` |
| iOS version | `not run` |
| Synthetic/demo location fixture | `not run` |
| Sanitized evidence identifier | `not run` |

## Verification Matrix

| Scenario | Expected evidence | Result | Evidence |
| --- | --- | --- | --- |
| Portable Make authority | `make root-test` rejects caller-controlled Make authority and path execution. | `not run` | `not run` |
| Static repository contract | `make lint` validates credentials, project metadata, vendored framework integrity, documentation, and source contracts. | `not run` | `not run` |
| Native policy tests | `swift test --disable-index-store` passes coordinate, token, style URL, authorization, freshness, and generation cases. | `not run` | `not run` |
| Hostile policy mutations | `ruby scripts/check_policy_mutations.rb` rejects all maintained policy and integration mutations. | `not run` | `not run` |
| Legacy x86_64 simulator build | `RUN_LEGACY_XCODE=1 make build` completes an unsigned `engagement` scheme build. | `not run` | `not run` |
| Missing/invalid token | App shows the generic local-configuration message without constructing a map or exposing token content. | `not run` | `not run` |
| Valid local token | App creates the map without checking the token or style URL into source control. | `not run` | `not run` |
| Default demo coordinates | Map center and one prize annotation use the reviewed fallback coordinates. | `not run` | `not run` |
| Valid local coordinate pairs | Complete finite nonzero coordinate pairs override the corresponding demo values without logging them. | `not run` | `not run` |
| Invalid/incomplete coordinate pairs | Missing, nonnumeric, out-of-range, non-finite, or `0,0` values retain the reviewed fallback. | `not run` | `not run` |
| Repeated appearance | Returning to the screen does not duplicate the prize annotation. | `not run` | `not run` |
| Annotation and callout | Prize and fallback pin images render safely and callouts remain available. | `not run` | `not run` |
| Permission denied/revoked | User following and active location sessions stop without logging precise coordinates. | `not run` | `not run` |
| Permission granted | Foreground when-in-use tracking starts only while the visible map owns the current request generation. | `not run` | `not run` |
| Recoverable location failure | A recoverable sample failure keeps the current session available for a later valid sample. | `not run` | `not run` |
| View disappearance | Leaving the map invalidates the current generation and disables user-location presentation. | `not run` | `not run` |
| Attribution and telemetry controls | Mapbox attribution and telemetry controls remain visible and usable. | `not run` | `not run` |
| Physical-device signing | Locally selected team and provisioning build/run without entering tracked project settings. | `not run` | `not run` |

## Completion Rule

Do not call the matrix complete until every required row has exact-commit
evidence. Keep unsupported or unavailable environments marked `blocked` or
`not run`; never convert absence of evidence into a pass.
