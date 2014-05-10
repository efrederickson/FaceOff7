ARCHS = armv7 armv7s arm64
CFLAGS = -fobjc-arc
TARGET = iphone:clang:7.1:7.1
THEOS_DEVICE_IP=192.168.7.146

include theos/makefiles/common.mk

TWEAK_NAME = FaceOff7
FaceOff7_FILES = common.m FOSettings.m FOAccelerometerHandler.m Tweak.xm
FaceOff7_FRAMEWORKS = UIKit CoreTelephony GraphicsServices AudioToolbox IOKit
FaceOff7_PRIVATE_FRAMEWORKS = SpringBoardServices
FaceOff7_LIBRARIES = flipswitch MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
