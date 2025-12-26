include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = NLIPClient
NLIPClient_OBJC_FILES = main.m \
                        NLIPClientAppDelegate.m \
                        NLIPClientController.m \
                        NLIPMessage.m
NLIPClient_RESOURCE_FILES = NLIPClientInfo.plist
NLIPClient_MAIN_MODEL_FILE = NLIPClient.gorm

ADDITIONAL_OBJCFLAGS = -Wall -Wno-deprecated-declarations
ADDITIONAL_LDFLAGS = -ldispatch -lgnustep-gui -lgnustep-base

include $(GNUSTEP_MAKEFILES)/application.make
