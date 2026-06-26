# Bounded Location Acquisition Design

Status: Completed

## Problem

The configured map screen starts continuous `CLLocationManager` updates while
waiting for the first fresh, accurate location. The session stops after an
accepted sample, a terminal manager error, authorization loss, or screen
disappearance. If Core Location supplies only rejected samples or repeated
recoverable `locationUnknown` failures while the screen stays visible, the
session has no terminal bound and can keep location hardware active.

Apple documents `startUpdatingLocation()` as an ongoing service and recommends
calling `stopUpdatingLocation()` when updates are no longer needed to save
power. The app still benefits from multiple samples because accuracy may improve
after an initially rejected fix.

## Options

1. Add a cancellable deadline to each `LocationAcquisitionSession`. This keeps
   accuracy-improvement behavior, bounds energy use, and fits the existing
   generation/identity ownership model.
2. Replace continuous updates with `requestLocation()`. This is naturally
   one-shot, but one stale or inaccurate result would leave the coordinator
   awaiting a session that Core Location has already stopped unless a new retry
   state machine is added.
3. Rely only on view disappearance and authorization callbacks. This preserves
   current code but leaves the observed unbounded visible-screen path intact.

## Decision

Use option 1. Each acquisition generation receives one 15-second main-queue
deadline. `stop()` cancels the pending deadline before clearing the location
manager delegate. A timeout is accepted only for the currently awaiting
generation and current session identity; stale timeouts cannot stop a newer
session. A current timeout stops Core Location, clears the session, and disables
Mapbox location presentation without logging coordinates or provider details.

## Validation

- Pure coordinator tests reject stale timeout generations and stop the current
  awaiting generation.
- The iOS source contract requires schedule, cancel, timeout callback, session
  identity, and terminal cleanup ordering.
- Hostile mutations remove cancellation, bypass generation identity, or make
  timeout recoverable.
- Root-independent checks, hosted Swift policy tests, mutation tests, and the
  legacy x86_64 unsigned simulator build remain required before merge.
- `make check` is the canonical combined gate.

## External Evidence

- Apple `startUpdatingLocation()` documentation describes ongoing updates after
  the initial fix.
- Apple `stopUpdatingLocation()` documentation recommends stopping delivery
  when location events are no longer needed to allow hardware power savings.
- Apple `requestLocation()` documentation confirms one-shot delivery, but that
  model does not preserve this app's improve-until-acceptable behavior without
  additional retry ownership.
