# YTSkipper: build the menu bar app as build/YTSkipper.app and run it from this repo.
# No Xcode required; SwiftPM builds the binary, this file wraps it into a bundle.

APP_NAME      := YTSkipper
BUNDLE_ID     := com.github.kanataidarov.ytskipper
CONFIGURATION := release
BUILD_DIR     := build
APP           := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS      := $(APP)/Contents
BINARY        := .build/$(CONFIGURATION)/$(APP_NAME)
TESTPAGE_PORT := 8765

# Command Line Tools ship the Swift Testing macro plugin in a folder SwiftPM does not search.
TESTING_PLUGINS := $(shell xcode-select -p)/usr/lib/swift/host/plugins/testing
TEST_FLAGS      := -Xswiftc -plugin-path -Xswiftc "$(TESTING_PLUGINS)"

.PHONY: all build bundle run stop test testpage clean

all: bundle

## Compile the Swift package.
build:
	swift build -c $(CONFIGURATION)

## Assemble and ad-hoc sign the .app bundle.
bundle: build
	rm -rf "$(APP)"
	mkdir -p "$(CONTENTS)/MacOS" "$(CONTENTS)/Resources"
	cp "$(BINARY)" "$(CONTENTS)/MacOS/$(APP_NAME)"
	cp Resources/Info.plist "$(CONTENTS)/Info.plist"
	printf 'APPL????' > "$(CONTENTS)/PkgInfo"
	codesign --force --sign - --identifier "$(BUNDLE_ID)" "$(APP)"
	@echo
	@echo "Built $(APP)."
	@echo "Ad-hoc signature: after every rebuild, remove and re-add $(APP_NAME) under"
	@echo "System Settings > Privacy & Security > Accessibility."

## Quit any running instance, rebuild, and launch.
run: stop bundle
	open "$(APP)"

## Quit a running instance, if any.
stop:
	-pkill -x $(APP_NAME) 2>/dev/null || true

## Unit tests for the decision logic (no Safari involved).
test:
	swift test $(TEST_FLAGS)

## Serve the local test page. Add "localhost" to hosts in docs/config.json while using it.
testpage:
	@echo "Open http://localhost:$(TESTPAGE_PORT)/skip-page.html in Safari."
	@echo "Add \"localhost\" to the hosts array in docs/config.json while testing; remove it afterwards."
	python3 -m http.server $(TESTPAGE_PORT) --bind 127.0.0.1 --directory Tests/Fixtures

clean: stop
	rm -rf "$(BUILD_DIR)" .build
