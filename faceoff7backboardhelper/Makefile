ARCHS = armv7 armv7s arm64
include theos/makefiles/common.mk

TWEAK_NAME = FaceOff7BackboardHelper
FaceOff7BackboardHelper_FILES = Tweak.xm
FaceOff7BackboardHelper_FRAMEWORKS = IOKit
FaceOff7BackboardHelper_PRIVATE_FRAMEWORKS = GraphicsServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
