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
authorization_transition_plan = 'docs/plans/2026-06-12-location-authorization-transitions.md'
mapbox_token_guard_plan = 'docs/plans/2026-06-12-mapbox-secret-token-guard.md'
mapbox_attribution_plan = 'docs/plans/2026-06-13-mapbox-attribution-telemetry-controls.md'
location_request_plan = 'docs/plans/2026-06-13-location-request-gating.md'
make_root_plan = 'docs/plans/2026-06-14-make-root-override-protection.md'
make_authority_plan = 'docs/plans/2026-06-21-make-authority-isolation.md'
coordinate_plan = 'docs/plans/2026-06-17-configurable-demo-coordinates.md'
failures << "#{canonical_plan} is missing" unless File.exist?(canonical_plan)
failures << "#{signing_team_plan} is missing" unless File.exist?(signing_team_plan)
failures << "#{ci_plan} is missing" unless File.exist?(ci_plan)
failures << "#{vendored_framework_plan} is missing" unless File.exist?(vendored_framework_plan)
failures << "#{authorization_transition_plan} is missing" unless File.exist?(authorization_transition_plan)
failures << "#{mapbox_token_guard_plan} is missing" unless File.exist?(mapbox_token_guard_plan)
failures << "#{mapbox_attribution_plan} is missing" unless File.exist?(mapbox_attribution_plan)
failures << "#{location_request_plan} is missing" unless File.exist?(location_request_plan)
failures << "#{make_root_plan} is missing" unless File.exist?(make_root_plan)
failures << "#{make_authority_plan} is missing" unless File.exist?(make_authority_plan)
failures << "#{coordinate_plan} is missing" unless File.exist?(coordinate_plan)
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
if info_plist.include?('MGLMapboxMetricsEnabledSettingShownInApp')
  failures << 'engagement/Info.plist must not retain the deprecated Mapbox metrics-setting flag'
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
coordinate_keys = %w[MAP_CENTER_LATITUDE MAP_CENTER_LONGITUDE PRIZE_LATITUDE PRIZE_LONGITUDE]
coordinate_keys.each do |key|
  unless info_plist.include?("<key>#{key}</key>") && info_plist.include?("<string>$(#{key})</string>")
    failures << "engagement/Info.plist must read #{key} from $(#{key})"
  end
  unless File.read('engagement/MapboxSecrets.xcconfig.example').include?("#{key} =")
    failures << "MapboxSecrets.xcconfig.example must expose optional #{key} configuration"
  end
end

tracked_files_output, tracked_files_error, tracked_files_status = Open3.capture3('git', 'ls-files', '-z')
if tracked_files_status.success?
  mapbox_token_pattern = /(?<![A-Za-z0-9])(?:pk|sk)\.[A-Za-z0-9._-]{20,}/
  tracked_files_output.split("\0").each do |path|
    next if path.start_with?('Pods/') || !File.file?(path)

    contents = File.binread(path)
    if contents.match?(mapbox_token_pattern)
      failures << "#{path} must not contain a checked-in Mapbox token"
    end
  end
else
  failures << "unable to scan tracked files for Mapbox tokens: #{tracked_files_error.strip}"
end

checker_source = File.read(__FILE__)
[
  ['(?:pk|', 'sk)\\.'].join,
  ["Open3.capture3('git', '", "ls-files', '-z')"].join,
  ["path.start_with?('", "Pods/')"].join,
  ['File.bin', 'read(path)'].join,
  ['contents.match?(', 'mapbox_token_pattern)'].join,
  ['must not contain a checked-in ', 'Mapbox token'].join
].each do |fragment|
  failures << "#{__FILE__} must retain Mapbox token guard fragment #{fragment.inspect}" unless checker_source.include?(fragment)
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
    },
    'apple' => {
      'runs-on' => 'macos-15',
      'timeout-minutes' => 15,
      'steps' => [
        {
          'name' => 'Check out repository',
          'uses' => 'actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10',
          'with' => { 'persist-credentials' => false }
        },
        {
          'name' => 'Run policy tests and Xcode build',
          'run' => 'RUN_LEGACY_XCODE=1 make check'
        }
      ]
    }
  }
}

begin
  workflow_config = YAML.safe_load(workflow, aliases: false)
  workflow_config['on'] = workflow_config.delete(true) if workflow_config.is_a?(Hash) && workflow_config.key?(true)
  failures << 'GitHub Actions workflow must keep the exact pinned, least-privilege static and Apple validation baseline' unless workflow_config == expected_workflow

  duplicate_keys = duplicate_yaml_keys(Psych.parse_stream(workflow))
  failures << "GitHub Actions workflow contains duplicate YAML keys: #{duplicate_keys.join(', ')}" unless duplicate_keys.empty?
rescue Psych::Exception => e
  failures << "GitHub Actions workflow must be valid YAML: #{e.message}"
end

makefile = File.read('Makefile')
root_declaration = %q(override ROOT := $(shell sed_path=/usr/bin/sed; [ -x "$$sed_path" ] || sed_path=/bin/sed; [ -x "$$sed_path" ] || exit 1; path=$$(printf '%s' '$(subst ','"'"',$(MAKEFILE_LIST))' | "$$sed_path" 's/^ //'); [ -f "$$path" ] || exit 1; directory=$${path%/*}; [ "$$directory" != "$$path" ] || directory=.; CDPATH= cd "$$directory" && pwd -P))
root_assignments = makefile.lines.map(&:chomp).grep(/\A(?:override\s+)?ROOT\s*[:?+]?=/)
required_make_authority = [
  'override SHELL := /bin/sh',
  'override .SHELLFLAGS := -c',
  '.SECONDEXPANSION:',
  'override RUBY := ruby',
  'override SWIFT := swift',
  'override SWIFT_TEST_FLAGS := --disable-index-store',
  '$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)',
  'override MAKEFILES :=',
  '$(error MAKEFILE_LIST must not be overridden)',
  root_declaration,
  'export ROOT',
  'export RUN_LEGACY_XCODE',
  'export XCODE_DERIVED_DATA',
  '$(error repository Makefile path could not be resolved)',
  'root-test:',
  "\t/bin/sh \"$$ROOT/scripts/test-makefile-root.sh\"",
  'verify: root-test lint test build'
]
makefile_lines = makefile.lines.map(&:chomp)
unless root_assignments == [root_declaration] &&
       required_make_authority.all? { |line| makefile_lines.include?(line) } &&
       makefile.include?('build check lint policy-mutation-test policy-test root-test test verify: $$(if $$(shell') &&
       makefile.include?('$$(error repository Makefile must be loaded alone))')
  failures << 'Makefile must preserve the isolated repository-owned verification authority contract'
end
unless makefile.include?('RUN_LEGACY_XCODE ?= 0') &&
       makefile.include?('xcodebuild is required when RUN_LEGACY_XCODE=1') &&
       makefile.include?('legacy Xcode build skipped')
  failures << 'Makefile must keep legacy Xcode compilation explicit and opt-in'
end

root_test = 'scripts/test-makefile-root.sh'
if File.exist?(root_test)
  root_test_text = File.read(root_test)
  ['104 executed target/authority cases', '2 inert configuration-data cases', 'MAKEFILE_LIST must not be overridden', 'MAKEFILES must be empty', 'repository Makefile path could not be resolved', 'repository Makefile must be loaded alone', 'detected MAKEFILES preload startup', '2 multi-Makefile rejections', '1 dollar-path non-execution case'].each do |evidence|
    failures << "#{root_test} must preserve #{evidence.inspect}" unless root_test_text.include?(evidence)
  end
else
  failures << "#{root_test} is missing"
end

if File.exist?(make_authority_plan)
  authority_plan = File.read(make_authority_plan)
  ['Status: Completed', '`make root-test` passed 104 target/authority cases', '`make check` passed from the repository and through an absolute Makefile path'].each do |evidence|
    failures << "#{make_authority_plan} must record verification evidence #{evidence.inspect}" unless authority_plan.include?(evidence)
  end
end

if File.exist?(make_root_plan)
  root_plan = File.read(make_root_plan)
  [
    'Status: Completed',
    '`make ROOT=/tmp check` passed',
    'all five public Make aliases passed',
    'Six hostile mutations were rejected',
    'Ruby 3.3'
  ].each do |evidence|
    failures << "#{make_root_plan} must record verification evidence #{evidence.inspect}" unless root_plan.include?(evidence)
  end
end

if File.exist?(coordinate_plan)
  coordinate_plan_text = File.read(coordinate_plan)
  [
    'Status: Completed',
    'focused coordinate contract passed',
    'make check passed',
    'Nine hostile coordinate mutations were rejected',
    'Exact diff'
  ].each do |evidence|
    failures << "#{coordinate_plan} must record verification evidence #{evidence.inspect}" unless coordinate_plan_text.include?(evidence)
  end
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
  document = File.read(doc_path).gsub(/\s+/, ' ')
  unless document.include?('GitHub Actions')
    failures << "#{doc_path} must document the GitHub Actions baseline"
  end
  unless document.include?('authorization transition')
    failures << "#{doc_path} must document the location authorization transition contract"
  end
  unless document.include?('request location authorization only from the undetermined state')
    failures << "#{doc_path} must document initial location authorization request gating"
  end
  unless document.include?('Mapbox token formats')
    failures << "#{doc_path} must document the tracked Mapbox token format guard"
  end
  unless document.include?('Mapbox style URL credentials')
    failures << "#{doc_path} must document the Mapbox style URL credential boundary"
  end
  unless document.include?('Mapbox attribution and telemetry controls')
    failures << "#{doc_path} must document the Mapbox attribution and telemetry controls"
  end
  unless document.include?('validated local coordinate overrides')
    failures << "#{doc_path} must document validated local coordinate overrides"
  end
end

unless File.read('README.md').include?(make_root_plan)
  failures << "README.md must reference #{make_root_plan}"
end
unless File.read('README.md').include?(coordinate_plan)
  failures << "README.md must reference #{coordinate_plan}"
end

view_controller = File.read('engagement/ViewController.swift')
policy_path = 'Sources/ScavengerHuntPolicies/AppPolicy.swift'
policy = File.exist?(policy_path) ? File.read(policy_path) : ''
policy_tests = File.exist?('PolicyTests/AppPolicyTests.swift') ? File.read('PolicyTests/AppPolicyTests.swift') : ''
storyboard = File.read('engagement/Base.lproj/Main.storyboard')

unless project_file.include?('../Sources/ScavengerHuntPolicies/AppPolicy.swift') &&
       project_file.include?('AppPolicy.swift in Sources')
  failures << 'TreasureHunt.xcodeproj must compile the shared runtime policy source'
end
unless project_file.scan('SWIFT_VERSION = 4.0;').length == 2 &&
       project_file.scan('IPHONEOS_DEPLOYMENT_TARGET = 12.0;').length >= 2
  failures << 'TreasureHunt.xcodeproj must use the supported Swift 4 and iOS 12 app baseline'
end
if storyboard.include?('customClass="MGLMapView"') || storyboard.include?('keyPath="showsUserLocation"')
  failures << 'Main.storyboard must not instantiate or pre-enable a Mapbox location view before runtime validation'
end
unless info_plist.include?('while this screen is visible') && info_plist.include?('Mapbox may process map and location data')
  failures << 'NSLocationWhenInUseUsageDescription must disclose visible-screen use and Mapbox processing'
end

unless view_controller.include?('AppConfigurationPolicy.mapboxAccessToken') &&
       view_controller.include?('MGLAccountManager.setAccessToken(token)') &&
       view_controller.index('MGLAccountManager.setAccessToken(token)') < view_controller.index('MGLMapView(')
  failures << 'ViewController.swift must validate and install a public Mapbox token before constructing the map'
end
unless view_controller.include?('AppConfigurationPolicy.mapStyleURL') &&
       view_controller.include?('AppConfigurationPolicy.coordinate')
  failures << 'ViewController.swift must use shared runtime policy for styles and coordinates'
end
unless view_controller.include?('configuredMapView.logoView.isHidden = false') &&
       view_controller.include?('configuredMapView.attributionButton.isHidden = false')
  failures << 'ViewController.swift must keep Mapbox logo, attribution, and telemetry controls visible'
end
if view_controller.match?(/(?:logoView|attributionButton)\.isHidden\s*=\s*true/) ||
   view_controller.match?(/(?:logoView|attributionButton)\.removeFromSuperview\s*\(/)
  failures << 'ViewController.swift must not hide or remove Mapbox attribution and telemetry controls'
end
unless view_controller.include?('navigationItem.titleView = UIImageView')
  failures << 'ViewController.swift must keep the logo owned by its navigation item lifecycle'
end

unless view_controller.include?('LocationTrackingPolicy.shouldRequestAuthorization') &&
       view_controller.include?('locationManager.requestWhenInUseAuthorization()') &&
       view_controller.include?('override func viewDidAppear')
  failures << 'ViewController.swift must defer and gate when-in-use authorization until the map screen is visible'
end
if view_controller.include?('requestAlwaysAuthorization()')
  failures << 'ViewController.swift must not request always-on location authorization'
end
unless view_controller.include?('override func viewWillDisappear') &&
       view_controller.include?('stopLocationTracking()') &&
       view_controller.include?('isAwaitingLocation = false')
  failures << 'ViewController.swift must stop and invalidate location ownership when leaving the screen'
end
unless view_controller.include?('LocationTrackingPolicy.shouldAccept') &&
       view_controller.include?('.max { $0.timestamp < $1.timestamp }') &&
       view_controller.include?('LocationSamplePolicy.accepts(location)')
  failures << 'ViewController.swift must reject stale, inaccurate, or stale-session location callbacks'
end
unless view_controller.include?('func locationManagerDidChangeAuthorization') &&
       view_controller.include?('didChangeAuthorization status: CLAuthorizationStatus')
  failures << 'ViewController.swift must handle both current and legacy authorization callbacks'
end
unless view_controller.scan('DispatchQueue.main.async').length >= 3
  failures << 'ViewController.swift must marshal asynchronous location callbacks onto the main queue'
end
unless view_controller.include?('mapView?.setUserTrackingMode(.none, animated: false)') &&
       view_controller.include?('mapView?.showsUserLocation = false') &&
       view_controller.include?('mapView?.setUserTrackingMode(.follow, animated: false)')
  failures << 'ViewController.swift must explicitly own Mapbox location tracking transitions'
end

unless policy.include?('maximumTokenLength = 1024') &&
       policy.include?('token.hasPrefix("pk.")') &&
       policy.include?('allowedTokenCharacters.inverted')
  failures << 'AppPolicy.swift must bound and validate public Mapbox access tokens'
end
unless policy.include?('maximumStyleURLLength = 2048') &&
       policy.include?('components.user == nil') &&
       policy.include?('components.password == nil') &&
       policy.include?('components.fragment == nil') &&
       policy.include?('sensitiveQueryNames') &&
       policy.include?('components.host?.lowercased() == "styles"') &&
       policy.include?('components.count == 2')
  failures << 'AppPolicy.swift must bound style URLs and reject credentials, fragments, and malformed Mapbox paths'
end
unless policy.include?('number.isFinite') &&
       policy.include?('CLLocationCoordinate2DIsValid(coordinate)') &&
       policy.include?('coordinate.latitude == 0 && coordinate.longitude == 0')
  failures << 'AppPolicy.swift must reject non-finite, out-of-range, and null-island sentinel coordinates'
end
unless policy.include?('maximumAge: TimeInterval = 30') &&
       policy.include?('maximumFutureSkew: TimeInterval = 5') &&
       policy.include?('maximumHorizontalAccuracy: CLLocationAccuracy = 100')
  failures << 'AppPolicy.swift must bound location freshness, future skew, and horizontal accuracy'
end

[
  'testCoordinateRejectsNullIslandSentinel',
  'testCoordinateRejectsNonFiniteValues',
  'testMapboxTokenRejectsSecretsPlaceholdersAndControlCharacters',
  'testMapStyleURLRejectsCredentialsAndSensitiveQueryItems',
  'testMapStyleURLRejectsFragmentsAndOversizedValues',
  'testRejectsStaleLocation',
  'testRejectsImplausiblyFutureLocation',
  'testStaleSessionCallbackIsRejected'
].each do |test_name|
  failures << "PolicyTests must retain #{test_name}" unless policy_tests.include?(test_name)
end
unless File.read('Makefile').include?('policy-mutation-test') &&
       File.exist?('scripts/check_policy_mutations.rb') &&
       File.read('scripts/check_policy_mutations.rb').include?('Killed #{mutations.length} policy mutations')
  failures << 'Makefile must run the focused Swift policy mutation suite on macOS'
end

if view_controller.match?(/annotation\.title!/) || view_controller.include?('manager.location!.coordinate')
  failures << 'ViewController.swift must not force unwrap annotation or location values'
end
if view_controller.match?(/print\s*\([^)]*(?:latitude|longitude|token)/mi)
  failures << 'ViewController.swift must not log precise coordinates or credentials'
end
unless view_controller.include?('guard let baseImage = UIImage(named: imageName) else')
  failures << 'ViewController.swift must guard marker image loading'
end
unless view_controller.include?('private var didAddPrizeAnnotation = false') &&
       view_controller.include?('!didAddPrizeAnnotation') &&
       view_controller.include?('didAddPrizeAnnotation = true')
  failures << 'ViewController.swift must not add duplicate prize annotations on repeated appearances'
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
