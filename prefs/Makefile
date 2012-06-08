include theos/makefiles/common.mk

BUNDLE_NAME = Aptdate
Aptdate_FILES = Aptdate.mm
Aptdate_INSTALL_PATH = /Library/PreferenceBundles
Aptdate_FRAMEWORKS = UIKit
Aptdate_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Aptdate.plist$(ECHO_END)
