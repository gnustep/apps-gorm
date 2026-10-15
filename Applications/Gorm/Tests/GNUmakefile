#
# Tests for the Gorm application resources.
#

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before running this!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

all::
	@(echo If you want to run the Gorm application testsuite, please type \'make check\')

check::
	(\
	LD_LIBRARY_PATH="$(TOP_DIR)/../../../GormCore/GormCore.framework/Versions/0:$(TOP_DIR)/../../../InterfaceBuilder/$(GNUSTEP_OBJ_DIR):$(TOP_DIR)/../../../GormObjCHeaderParser/$(GNUSTEP_OBJ_DIR):$${LD_LIBRARY_PATH}";\
	export LD_LIBRARY_PATH;\
	if [ "$(DEBUG)" = "" ]; then \
	  gnustep-tests application;\
	else \
	  gnustep-tests --debug application;\
	fi; \
	)

clean::
	-gnustep-tests --clean

include $(GNUSTEP_MAKEFILES)/rules.make
