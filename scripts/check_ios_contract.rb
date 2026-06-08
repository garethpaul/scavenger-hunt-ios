#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

failures = []

docs_plans = Dir['docs/plans/*.md'].sort
canonical_plan = 'docs/plans/2026-06-08-scavenger-hunt-ios-baseline.md'
failures << "#{canonical_plan} is missing" unless File.exist?(canonical_plan)
failures << 'docs/plans must contain at least one completed plan' if docs_plans.empty?

docs_plans.each do |plan_path|
  plan = File.read(plan_path)
  unless plan.include?('Status: Completed') && plan.include?('make check')
    failures << "#{plan_path} must record completed status and make check verification"
  end
end

info_plist = File.read('engagement/Info.plist')
if info_plist.match?(/<string>pk\.[^<]+<\/string>/)
  failures << 'engagement/Info.plist must not contain a checked-in Mapbox access token'
end
unless info_plist.include?('<string>$(MAPBOX_ACCESS_TOKEN)</string>')
  failures << 'engagement/Info.plist must read MGLMapboxAccessToken from $(MAPBOX_ACCESS_TOKEN)'
end
if info_plist.include?('<key>MGLMapboxMetricsEnabledSettingShownInApp </key>')
  failures << 'MGLMapboxMetricsEnabledSettingShownInApp key must not contain trailing whitespace'
end
if info_plist.include?('treaure')
  failures << 'NSLocationWhenInUseUsageDescription contains a typo'
end
unless File.read('.gitignore').include?('engagement/MapboxSecrets.xcconfig')
  failures << '.gitignore must ignore local MapboxSecrets.xcconfig'
end
unless File.read('engagement/MapboxSecrets.xcconfig.example').include?('replace-with-mapbox-public-token')
  failures << 'MapboxSecrets.xcconfig.example must contain a placeholder token'
end

view_controller = File.read('engagement/ViewController.swift')
if view_controller.include?('URL(string: "")')
  failures << 'ViewController.swift must not pass a blank Mapbox style URL'
end
if view_controller.match?(/annotation\.title!/)
  failures << 'ViewController.swift must not force unwrap annotation titles'
end
if view_controller.include?('var image: UIImage!')
  failures << 'ViewController.swift must not force unwrap marker images'
end
if view_controller.match?(/UIImage\(named:\s*"Logo"\)!/)
  failures << 'ViewController.swift must not force unwrap the logo asset'
end
if view_controller.include?('manager.location!.coordinate')
  failures << 'ViewController.swift must use didUpdateLocations values without force unwrapping manager.location'
end
unless view_controller.include?('let annotationTitle = annotation.title ?? nil')
  failures << 'ViewController.swift must flatten optional Mapbox annotation titles before reuse'
end
unless view_controller.include?('guard let baseImage = UIImage(named: imageName) else')
  failures << 'ViewController.swift must guard marker image loading'
end
unless view_controller.include?('let reuseIdentifier = annotationTitle ?? imageName')
  failures << 'ViewController.swift must provide a fallback marker reuse identifier'
end

asset_names = Dir['engagement/Assets.xcassets/**/*.imageset'].map { |path| File.basename(path, '.imageset') }
%w[Logo pin3 BluePin].each do |image_name|
  failures << "missing required annotation asset #{image_name}" unless asset_names.include?(image_name)
end
view_controller.scan(/UIImage\(named:\s*"([^"]+)"/).flatten.each do |image_name|
  failures << "missing asset for UIImage(named: \"#{image_name}\")" unless asset_names.include?(image_name)
end

Dir['engagement/Assets.xcassets/**/Contents.json'].each do |path|
  contents = JSON.parse(File.read(path))
  Array(contents['images']).each do |image|
    filename = image['filename']
    next if filename.to_s.empty?

    image_path = File.join(File.dirname(path), filename)
    failures << "#{path} references missing image #{filename}" unless File.file?(image_path)
  end
rescue JSON::ParserError => e
  failures << "#{path} is invalid JSON: #{e.message}"
end

if File.read('Podfile.lock') != File.read('Pods/Manifest.lock')
  failures << 'Podfile.lock and Pods/Manifest.lock differ; run pod install before committing'
end

if failures.empty?
  puts 'iOS contract checks passed'
else
  warn "iOS contract checks failed:\n- #{failures.join("\n- ")}"
  exit 1
end
