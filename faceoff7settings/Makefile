include theos/makefiles/common.mk
ARCHS=armv7 armv7s arm64
BUNDLE_NAME = FaceOff7Settings
FaceOff7Settings_FILES = FaceOff7Settings.mm
FaceOff7Settings_INSTALL_PATH = /Library/PreferenceBundles
FaceOff7Settings_FRAMEWORKS = UIKit
FaceOff7Settings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/FaceOff7Settings.plist$(ECHO_END)
