#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'

ROOT = File.expand_path('..', __dir__)
SOURCE = File.join(ROOT, 'Sources/ScavengerHuntPolicies/AppPolicy.swift')
VIEW_CONTROLLER = File.join(ROOT, 'engagement/ViewController.swift')
SCRATCH_PATH = File.join(ROOT, '.build')

mutations = {
  'accept null-island sentinel' => ['!(coordinate.latitude == 0 && coordinate.longitude == 0)', '!false'],
  'accept invalid coordinates' => ['CLLocationCoordinate2DIsValid(coordinate)', 'true'],
  'accept secret token prefix' => ['token.hasPrefix("pk.")', 'true'],
  'allow oversized tokens' => ['maximumTokenLength = 1024', 'maximumTokenLength = 4096'],
  'allow credential query items' => ['["access_token", "api_key", "apikey", "key", "token"]', '["api_key", "apikey", "key", "token"]'],
  'allow URL fragments' => ['components.fragment == nil', 'true'],
  'allow extra Mapbox path components' => ['components.count == 2', 'components.count >= 2'],
  'allow stale location samples' => ['maximumAge: TimeInterval = 30', 'maximumAge: TimeInterval = 300'],
  'allow inaccurate location samples' => ['maximumHorizontalAccuracy: CLLocationAccuracy = 100', 'maximumHorizontalAccuracy: CLLocationAccuracy = 1000'],
  'start duplicate own-manager sessions' => ['guard case .stopped = state, lastGeneration < UInt64.max else {', 'guard lastGeneration < UInt64.max else {'],
  'reuse an earlier manager generation' => ['lastGeneration += 1', '_ = lastGeneration'],
  'accept a sample without current-generation ownership' => [
    "guard case .awaitingOwnManagerLocation(let activeGeneration) = state,\n              activeGeneration == generation else {",
    "guard case .awaitingOwnManagerLocation = state else {"
  ],
  'fail to transfer ownership to Mapbox' => ['state = .mapboxTracking(generation: generation)', 'state = .stopped'],
  'allow an inactive generation failure to stop the current session' => [
    "guard case .awaitingOwnManagerLocation(let activeGeneration) = state,\n              activeGeneration == generation else {\n            return .ignoredInactive",
    "guard case .awaitingOwnManagerLocation = state else {\n            return .ignoredInactive"
  ],
  'make recoverable manager failures terminal' => ['guard !isRecoverable else {', 'guard isRecoverable else {'],
  'ignore terminal manager failures' => ["state = .stopped\n        return .stopped", 'return .ignoredRecoverable'],
  'misclassify locationUnknown as terminal' => ['error.code == CLError.locationUnknown.rawValue', 'error.code != CLError.locationUnknown.rawValue'],
  'accept a rejected Mapbox sample' => ['return .ignoredRecoverable', 'return .accepted'],
  'disable tracking after a rejected Mapbox sample' => [
    "guard let location = location, LocationSamplePolicy.accepts(location, now: now) else {\n            return .ignoredRecoverable",
    "guard let location = location, LocationSamplePolicy.accepts(location, now: now) else {\n            state = .stopped\n            return .ignoredRecoverable"
  ],
  'accept a Mapbox sample after a terminal stop' => ['return .ignoredStopped', 'return .accepted'],
  'ignore terminal stops' => [
    "mutating func stop(reason: LocationTrackingStopReason) {\n        state = .stopped",
    "mutating func stop(reason: LocationTrackingStopReason) {\n        _ = reason"
  ]
}.freeze

integration_mutations = {
  'stop tracking after a recoverable Mapbox sample' => [
    "guard locationTrackingCoordinator.handleMapboxSample(userLocation?.location) == .accepted else {\n            return",
    "guard locationTrackingCoordinator.handleMapboxSample(userLocation?.location) == .accepted else {\n            stopLocationTracking(reason: .managerFailed)\n            return"
  ],
  'disable Mapbox presentation after a recoverable sample' => [
    "guard locationTrackingCoordinator.handleMapboxSample(userLocation?.location) == .accepted else {\n            return",
    "guard locationTrackingCoordinator.handleMapboxSample(userLocation?.location) == .accepted else {\n            mapView.showsUserLocation = false\n            return"
  ],
  'bypass the coordinator in the Mapbox delegate' => [
    'locationTrackingCoordinator.handleMapboxSample(userLocation?.location)',
    'LocationSamplePolicy.accepts(userLocation!.location!)'
  ],
  'skip the lifecycle terminal stop' => [
    'stopLocationTracking(reason: .viewDisappeared)',
    'locationTrackingCoordinator.stop(reason: .viewDisappeared)'
  ],
  'skip the authorization terminal stop' => [
    "guard state == .authorized else {\n            stopLocationTracking(reason: .authorizationLost)\n            return\n        }",
    "if state == .restricted || state == .denied {\n            stopLocationTracking(reason: .authorizationLost)\n            return\n        }"
  ],
  'make locationUnknown terminal in production' => [
    'isRecoverable: LocationManagerErrorPolicy.isRecoverable(error)',
    'isRecoverable: false'
  ],
  'allow a stale success session to claim the current generation' => [
    'self.locationAcquisitionSession === session,',
    'self.locationAcquisitionSession != nil,'
  ],
  'allow a stale failure session to stop the current generation' => [
    'guard result == .stopped, self.locationAcquisitionSession === session else {',
    'guard result == .stopped, self.locationAcquisitionSession != nil else {'
  ]
}.freeze

original = File.read(SOURCE)
original_view_controller = File.read(VIEW_CONTROLLER)

begin
  mutations.each do |name, (before, after)|
    unless original.include?(before)
      abort "mutation source missing for #{name}"
    end

    File.write(SOURCE, original.sub(before, after))
    output, error, status = Open3.capture3(
      'swift', 'test', '--disable-index-store', '--package-path', ROOT, '--scratch-path', SCRATCH_PATH
    )
    if status.success?
      warn output
      warn error
      abort "mutation survived: #{name}"
    end
  end

  File.write(SOURCE, original)

  integration_mutations.each do |name, (before, after)|
    unless original_view_controller.include?(before)
      abort "integration mutation source missing for #{name}"
    end

    File.write(VIEW_CONTROLLER, original_view_controller.sub(before, after))
    output, error, status = Open3.capture3('ruby', File.join(ROOT, 'scripts/check_ios_contract.rb'), chdir: ROOT)
    if status.success?
      warn output
      warn error
      abort "integration mutation survived: #{name}"
    end
    File.write(VIEW_CONTROLLER, original_view_controller)
  end
ensure
  File.write(SOURCE, original)
  File.write(VIEW_CONTROLLER, original_view_controller)
end

puts "Killed #{mutations.length} policy mutations"
puts "Killed #{integration_mutations.length} location integration mutations"
