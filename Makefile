override ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
RUBY ?= ruby
RUN_LEGACY_XCODE ?= 0
SWIFT ?= swift
SWIFT_TEST_FLAGS ?= --disable-index-store
XCODE_DERIVED_DATA ?= .build/XcodeDerivedData

.PHONY: build check lint policy-mutation-test policy-test test verify

lint:
	cd "$(ROOT)" && $(RUBY) scripts/check_ios_contract.rb

policy-test:
	@if [ "$$(uname -s)" = "Darwin" ]; then \
		cd "$(ROOT)" && $(SWIFT) test $(SWIFT_TEST_FLAGS); \
	else \
		echo "Swift policy tests skipped; CoreLocation policies require macOS"; \
	fi

policy-mutation-test:
	@if [ "$$(uname -s)" = "Darwin" ]; then \
		cd "$(ROOT)" && $(RUBY) scripts/check_policy_mutations.rb; \
	else \
		echo "Swift policy mutations skipped; CoreLocation policies require macOS"; \
	fi

test: lint policy-test policy-mutation-test

build:
	@if [ "$(RUN_LEGACY_XCODE)" = "1" ]; then \
		command -v xcodebuild >/dev/null 2>&1 || { echo "xcodebuild is required when RUN_LEGACY_XCODE=1"; exit 1; }; \
		cd "$(ROOT)" && xcodebuild -workspace engagement.xcworkspace -scheme engagement -configuration Debug -sdk iphonesimulator -arch x86_64 -derivedDataPath "$(XCODE_DERIVED_DATA)" CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build ; \
	else \
		echo "legacy Xcode build skipped; set RUN_LEGACY_XCODE=1 on a compatible macOS toolchain"; \
	fi

verify: lint test build

check: verify
