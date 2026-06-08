.PHONY: lint test build verify

lint:
	ruby scripts/check_ios_contract.rb

test: lint

build:
	@if command -v xcodebuild >/dev/null 2>&1; then \
		xcodebuild -workspace engagement.xcworkspace -scheme engagement -sdk iphonesimulator build ; \
	else \
		echo "xcodebuild unavailable; compile check not run"; \
	fi

verify: lint test build
