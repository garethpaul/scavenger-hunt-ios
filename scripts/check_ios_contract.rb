#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'digest'
require 'open3'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
Dir.chdir(ROOT)

def duplicate_yaml_keys(node, path = [], duplicates = [])
  case node
  when Psych::Nodes::Mapping
    seen = {}
    node.children.each_slice(2) do |key_node, value_node|
      key = key_node.value
      duplicates << (path + [key]).join('.') if seen[key]
      seen[key] = true
      duplicate_yaml_keys(value_node, path + [key], duplicates)
    end
  when Psych::Nodes::Sequence
    node.children.each_with_index do |child, index|
      duplicate_yaml_keys(child, path + [index.to_s], duplicates)
    end
  else
    Array(node.children).each { |child| duplicate_yaml_keys(child, path, duplicates) } if node.respond_to?(:children)
  end

  duplicates
end

failures = []

docs_plans = Dir['docs/plans/*.md'].sort
canonical_plan = 'docs/plans/2026-06-08-scavenger-hunt-ios-baseline.md'
signing_team_plan = 'docs/plans/2026-06-09-local-signing-team-guard.md'
ci_plan = 'docs/plans/2026-06-10-ci-baseline.md'
vendored_framework_plan = 'docs/plans/2026-06-10-vendored-framework-integrity.md'
failures << "#{canonical_plan} is missing" unless File.exist?(canonical_plan)
failures << "#{signing_team_plan} is missing" unless File.exist?(signing_team_plan)
failures << "#{ci_plan} is missing" unless File.exist?(ci_plan)
failures << "#{vendored_framework_plan} is missing" unless File.exist?(vendored_framework_plan)
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
if info_plist.match?(/<string>mapbox:\/\/styles\/[^<]+<\/string>/)
  failures << 'engagement/Info.plist must not contain a checked-in Mapbox style URL'
end
unless info_plist.include?('<key>MAPBOX_STYLE_URL</key>') &&
       info_plist.include?('<string>$(MAPBOX_STYLE_URL)</string>')
  failures << 'engagement/Info.plist must read MAPBOX_STYLE_URL from $(MAPBOX_STYLE_URL)'
end
if info_plist.include?('NSLocationAlways') ||
   info_plist.include?('NSLocationAlwaysAndWhenInUseUsageDescription')
  failures << 'engagement/Info.plist must not request always-on location authorization'
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
unless File.read('engagement/MapboxSecrets.xcconfig.example').include?('MAPBOX_STYLE_URL =')
  failures << 'MapboxSecrets.xcconfig.example must expose optional MAPBOX_STYLE_URL configuration'
end

workspace = File.read('engagement.xcworkspace/contents.xcworkspacedata')
if workspace.include?('/Users/')
  failures << 'engagement.xcworkspace must not reference a developer-local absolute path'
end
unless workspace.include?('location = "group:TreasureHunt.xcodeproj"')
  failures << 'engagement.xcworkspace must reference TreasureHunt.xcodeproj relative to the workspace'
end

shared_scheme_path = 'TreasureHunt.xcodeproj/xcshareddata/xcschemes/engagement.xcscheme'
if File.exist?(shared_scheme_path)
  shared_scheme = File.read(shared_scheme_path)
  unless shared_scheme.include?('BuildableName = "engagement.app"') &&
         shared_scheme.include?('ReferencedContainer = "container:TreasureHunt.xcodeproj"')
    failures << "#{shared_scheme_path} must define a shared engagement app scheme for TreasureHunt.xcodeproj"
  end
else
  failures << "#{shared_scheme_path} is missing"
end

tracked_user_state_output, tracked_user_state_error, tracked_user_state_status = Open3.capture3(
  'git', 'ls-files', '*xcuserdata*', '*.xcuserstate'
)
if tracked_user_state_status.success?
  tracked_user_state = tracked_user_state_output.split("\n").select { |path| File.exist?(path) }
  unless tracked_user_state.empty?
    failures << "developer-local Xcode user state must not be tracked: #{tracked_user_state.join(', ')}"
  end
else
  failures << "unable to inspect tracked Xcode user state: #{tracked_user_state_error.strip}"
end

project_file = File.read('TreasureHunt.xcodeproj/project.pbxproj')
project_file.scan(/DEVELOPMENT_TEAM = ([^;]+);/).flatten.each do |team|
  unless team.delete('"').strip.empty?
    failures << 'TreasureHunt.xcodeproj must leave DEVELOPMENT_TEAM blank for local signing configuration'
  end
end

workflow_path = '.github/workflows/check.yml'
workflow = File.exist?(workflow_path) ? File.read(workflow_path) : ''
expected_workflow = {
  'name' => 'Check',
  'on' => {
    'pull_request' => nil,
    'push' => { 'branches' => ['master'] },
    'workflow_dispatch' => nil
  },
  'permissions' => { 'contents' => 'read' },
  'concurrency' => {
    'group' => 'check-${{ github.workflow }}-${{ github.ref }}',
    'cancel-in-progress' => true
  },
  'jobs' => {
    'check' => {
      'runs-on' => 'ubuntu-24.04',
      'timeout-minutes' => 5,
      'steps' => [
        {
          'name' => 'Check out repository',
          'uses' => 'actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10',
          'with' => { 'persist-credentials' => false }
        },
        {
          'name' => 'Set up Ruby',
          'uses' => 'ruby/setup-ruby@12fd324f1d0b43274fdc8130f6980590a667c455',
          'with' => { 'ruby-version' => '3.3' }
        },
        {
          'name' => 'Run static contract',
          'run' => 'make check'
        }
      ]
    }
  }
}

begin
  workflow_config = YAML.safe_load(workflow, aliases: false)
  workflow_config['on'] = workflow_config.delete(true) if workflow_config.is_a?(Hash) && workflow_config.key?(true)
  failures << 'GitHub Actions workflow must keep the exact pinned, least-privilege Ruby 3.3 check baseline' unless workflow_config == expected_workflow

  duplicate_keys = duplicate_yaml_keys(Psych.parse_stream(workflow))
  failures << "GitHub Actions workflow contains duplicate YAML keys: #{duplicate_keys.join(', ')}" unless duplicate_keys.empty?
rescue Psych::Exception => e
  failures << "GitHub Actions workflow must be valid YAML: #{e.message}"
end

makefile = File.read('Makefile')
unless makefile.include?('RUN_LEGACY_XCODE ?= 0') &&
       makefile.include?('xcodebuild is required when RUN_LEGACY_XCODE=1') &&
       makefile.include?('legacy Xcode build skipped')
  failures << 'Makefile must keep legacy Xcode compilation explicit and opt-in'
end

framework_manifest = 'VENDORED_FRAMEWORKS.sha256'
framework_binary = 'Pods/Mapbox-iOS-SDK/dynamic/Mapbox.framework/Mapbox'
if File.exist?(framework_manifest)
  line = File.read(framework_manifest).strip
  match = line.match(/\A([a-f0-9]{64})  (Pods\/Mapbox-iOS-SDK\/dynamic\/Mapbox\.framework\/Mapbox)\z/)
  if match.nil?
    failures << "#{framework_manifest} must contain the Mapbox framework SHA-256 entry"
  elsif !File.exist?(framework_binary)
    failures << "#{framework_binary} is missing"
  elsif Digest::SHA256.file(framework_binary).hexdigest != match[1]
    failures << "#{framework_binary} does not match its checked-in SHA-256 digest"
  end
else
  failures << "#{framework_manifest} is missing"
end

%w[README.md VISION.md SECURITY.md CHANGES.md].each do |doc_path|
  unless File.read(doc_path).include?('GitHub Actions')
    failures << "#{doc_path} must document the GitHub Actions baseline"
  end
end

view_controller = File.read('engagement/ViewController.swift')
if view_controller.include?('URL(string: "")')
  failures << 'ViewController.swift must not pass a blank Mapbox style URL'
end
if view_controller.match?(/mapbox:\/\/styles\//)
  failures << 'ViewController.swift must not contain a checked-in Mapbox style URL'
end
if view_controller.include?('let styleURL: URL? = nil')
  failures << 'ViewController.swift must resolve Mapbox style URLs from local configuration'
end
unless view_controller.include?('private func configuredMapStyleURL() -> URL?')
  failures << 'ViewController.swift must define an optional Mapbox style URL helper'
end
unless view_controller.include?('Bundle.main.object(forInfoDictionaryKey: "MAPBOX_STYLE_URL")')
  failures << 'ViewController.swift must read MAPBOX_STYLE_URL from Info.plist'
end
unless view_controller.include?('!trimmedStyleURL.contains("$(")')
  failures << 'ViewController.swift must ignore unresolved MAPBOX_STYLE_URL build placeholders'
end
unless view_controller.include?('let allowedStyleURLSchemes = ["mapbox", "https"]') &&
       view_controller.include?('styleURL.scheme?.lowercased()') &&
       view_controller.include?('allowedStyleURLSchemes.contains(styleURLScheme)')
  failures << 'ViewController.swift must restrict configured Mapbox style URLs to mapbox or https schemes'
end
unless view_controller.include?('styleURL.host?.lowercased() == "styles"')
  failures << 'ViewController.swift must require the styles authority for mapbox style URLs'
end
unless view_controller.include?('guard let styleURLHost = styleURL.host, !styleURLHost.isEmpty')
  failures << 'ViewController.swift must require a host for https style URLs'
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
if view_controller.match?(/print\s*\(\s*"locations\s*=/) ||
   view_controller.match?(/print\s*\([^)]*\.latitude[^)]*\.longitude/m)
  failures << 'ViewController.swift must not log precise user coordinates'
end
unless view_controller.include?('locationManager.delegate = self')
  failures << 'ViewController.swift must assign the location manager delegate before requesting authorization'
end
unless view_controller.include?('locationManager.requestWhenInUseAuthorization()')
  failures << 'ViewController.swift must request when-in-use location authorization'
end
if view_controller.include?('requestAlwaysAuthorization()')
  failures << 'ViewController.swift must not request always-on location authorization'
end
if view_controller.include?('mapView.userTrackingMode = .follow')
  failures << 'ViewController.swift must not enable Mapbox user tracking before checking authorization'
end
unless view_controller.include?('private func enableUserTrackingIfAuthorized()')
  failures << 'ViewController.swift must define an authorization-gated user tracking helper'
end
unless view_controller.include?('CLLocationManager.authorizationStatus()')
  failures << 'ViewController.swift must read CLLocationManager.authorizationStatus before following the user'
end
unless view_controller.include?('func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)')
  failures << 'ViewController.swift must retry user tracking when location authorization changes'
end
unless view_controller.include?('mapView?.userTrackingMode = .follow')
  failures << 'ViewController.swift must enable user tracking through optional map access after authorization'
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
unless view_controller.include?('private var didAddPrizeAnnotation = false')
  failures << 'ViewController.swift must track whether the prize annotation was already added'
end
unless view_controller.include?('guard !didAddPrizeAnnotation else')
  failures << 'ViewController.swift must not add duplicate prize annotations on repeated appearances'
end
unless view_controller.include?('didAddPrizeAnnotation = true')
  failures << 'ViewController.swift must mark the prize annotation as added'
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
