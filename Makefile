THEOS_DEVICE_IP=192.168.7.146
#THEOS_DEVICE_IP=192.168.7.206
THEOS_DEVICE_PORT=22

include theos/makefiles/common.mk

#CFLAGS = -fobjc-arc
ARCHS = armv7 armv7s arm64

TWEAK_NAME = FaceOff7
FaceOff7_FILES = Tweak.xm
FaceOff7_FRAMEWORKS = UIKit CoreTelephony AudioToolbox
FaceOff7_LIBRARIES = flipswitch MobileGestalt
FaceOff7_PRIVATE_FRAMEWORKS = SpringBoardServices GraphicsServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard; killall -9 backboardd"

SUBPROJECTS += faceoff7settings
SUBPROJECTS += faceoff7flipswitchtoggle
SUBPROJECTS += faceoff7backboardhelper
include $(THEOS_MAKE_PATH)/aggregate.mk
