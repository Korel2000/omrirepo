TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppDataHebrew
AppDataHebrew_FILES = Tweak.x
AppDataHebrew_CFLAGS = -fobjc-arc
AppDataHebrew_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
