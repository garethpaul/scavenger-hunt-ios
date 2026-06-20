#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'

ROOT = File.expand_path('..', __dir__)
SOURCE = File.join(ROOT, 'Sources/ScavengerHuntPolicies/AppPolicy.swift')
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
  'allow inaccurate location samples' => ['maximumHorizontalAccuracy: CLLocationAccuracy = 100', 'maximumHorizontalAccuracy: CLLocationAccuracy = 1000']
}.freeze

original = File.read(SOURCE)

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
ensure
  File.write(SOURCE, original)
end

puts "Killed #{mutations.length} policy mutations"
