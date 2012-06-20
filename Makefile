include theos/makefiles/common.mk

BUNDLE_NAME = Aptdate AptdateStats

Aptdate_FILES = Tweak.xm
Aptdate_FRAMEWORKS = AudioToolbox UIKit
Aptdate_PRIVATE_FRAMEWORKS = AppSupport BulletinBoard
Aptdate_INSTALL_PATH = /Library/WeeLoader/BulletinBoardPlugins
THEOS_IPHONEOS_DEPLOYMENT_VERSION = 5.0

#AptdateStats_FILES = Widget.mm
#AptdateStats_INSTALL_PATH = /Library/WeeLoader/Plugins
#AptdateStats_FRAMEWORKS = UIKit CoreGraphics

TOOL_NAME = aptdated
aptdated_FILES = aptdated.mm
aptdated_PRIVATE_FRAMEWORKS = AppSupport

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tool.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)echo " Compressing files..."$(ECHO_END)
	$(ECHO_NOTHING)find -L _/ -name "*.plist" -not -xtype l -print0|xargs -0 plutil -convert binary1;exit 0$(ECHO_END)
	$(ECHO_NOTHING)find -L _/ -name "*.png" -not -xtype l -print0|xargs -0 pincrush -i$(ECHO_END)
	$(ECHO_NOTHING)find -L _/ -name "*~" -delete$(ECHO_END)
	$(ECHO_NOTHING)chown root:wheel _/System/Library/LaunchDaemons/ws.hbang.aptdated.plist$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
