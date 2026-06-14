override ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RUBY ?= ruby
RUN_LEGACY_XCODE ?= 0

.PHONY: build check lint test verify

lint:
	cd "$(ROOT)" && $(RUBY) scripts/check_ios_contract.rb

test: lint

build:
	@if [ "$(RUN_LEGACY_XCODE)" = "1" ]; then \
		command -v xcodebuild >/dev/null 2>&1 || { echo "xcodebuild is required when RUN_LEGACY_XCODE=1"; exit 1; }; \
		cd "$(ROOT)" && xcodebuild -workspace engagement.xcworkspace -scheme engagement -sdk iphonesimulator build ; \
	else \
		echo "legacy Xcode build skipped; set RUN_LEGACY_XCODE=1 on a compatible macOS toolchain"; \
	fi

verify: lint test build

check: verify
