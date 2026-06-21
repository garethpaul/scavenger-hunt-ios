.PHONY: build check lint policy-mutation-test policy-test root-test test verify

override SHELL := /bin/sh
override .SHELLFLAGS := -c
override RUBY := ruby
override SWIFT := swift
override SWIFT_TEST_FLAGS := --disable-index-store
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override ROOT := $(shell path='$(subst ','"'"',$(MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /bin/sed 's/^ //'); [ -f "$$path" ] || exit 1; directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)
export ROOT
ifeq ($(strip $(ROOT)),)
$(error repository Makefile path could not be resolved)
endif

RUN_LEGACY_XCODE ?= 0
XCODE_DERIVED_DATA ?= .build/XcodeDerivedData
export RUN_LEGACY_XCODE
export XCODE_DERIVED_DATA

lint:
	cd "$$ROOT" && $(RUBY) scripts/check_ios_contract.rb

policy-test:
	@if [ "$$(uname -s)" = "Darwin" ]; then \
		cd "$$ROOT" && $(SWIFT) test $(SWIFT_TEST_FLAGS); \
	else \
		echo "Swift policy tests skipped; CoreLocation policies require macOS"; \
	fi

policy-mutation-test:
	@if [ "$$(uname -s)" = "Darwin" ]; then \
		cd "$$ROOT" && $(RUBY) scripts/check_policy_mutations.rb; \
	else \
		echo "Swift policy mutations skipped; CoreLocation policies require macOS"; \
	fi

test: lint policy-test policy-mutation-test

build:
	@if [ "$$RUN_LEGACY_XCODE" = "1" ]; then \
		command -v xcodebuild >/dev/null 2>&1 || { echo "xcodebuild is required when RUN_LEGACY_XCODE=1"; exit 1; }; \
		cd "$$ROOT" && xcodebuild -workspace engagement.xcworkspace -scheme engagement -configuration Debug -sdk iphonesimulator -arch x86_64 -derivedDataPath "$$XCODE_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build ; \
	else \
		echo "legacy Xcode build skipped; set RUN_LEGACY_XCODE=1 on a compatible macOS toolchain"; \
	fi

root-test:
	/bin/sh "$$ROOT/scripts/test-makefile-root.sh"

verify: root-test lint test build

check: verify
