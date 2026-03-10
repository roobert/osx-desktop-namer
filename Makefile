APP_NAME = DesktopNamer
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
DMG_NAME = $(APP_NAME).dmg
SIGNING_IDENTITY = Developer ID Application: Rob Wilson (NVA2TBQ5UN)
TEAM_ID = NVA2TBQ5UN
BUNDLE_ID = com.desktopnamer.app

.PHONY: build install run clean sign notarize dmg

build:
	swift build -c release

install: build
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	cp SupportFiles/Info.plist "$(APP_BUNDLE)/Contents/"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"

sign: install
	codesign --force --options runtime --sign "$(SIGNING_IDENTITY)" \
		--identifier "$(BUNDLE_ID)" \
		--timestamp \
		"$(APP_BUNDLE)"

dmg: sign
	rm -f "$(DMG_NAME)"
	hdiutil create -volname "$(APP_NAME)" -srcfolder "$(APP_BUNDLE)" \
		-ov -format UDZO "$(DMG_NAME)"
	codesign --force --sign "$(SIGNING_IDENTITY)" --timestamp "$(DMG_NAME)"

notarize: dmg
	xcrun notarytool submit "$(DMG_NAME)" \
		--keychain-profile "DesktopNamer" \
		--wait
	xcrun stapler staple "$(DMG_NAME)"

run: install
	open "$(APP_BUNDLE)"

clean:
	rm -rf .build "$(APP_BUNDLE)" "$(DMG_NAME)"
