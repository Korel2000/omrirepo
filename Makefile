export THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IOSProgrammingHebrew
IOSProgrammingHebrew_FILES = Tweak.x
IOSProgrammingHebrew_FRAMEWORKS = UIKit Foundation
IOSProgrammingHebrew_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
