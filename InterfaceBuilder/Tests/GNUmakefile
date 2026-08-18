#
# Tests for the InterfaceBuilder library.
#

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before running this!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

TOP_DIR := $(shell dirname $(CURDIR))

all::
	@(echo If you want to run the InterfaceBuilder testsuite, please type \'make check\')

check::
	(\
	ADDITIONAL_INCLUDE_DIRS="-I$(TOP_DIR)/.. -I$(TOP_DIR)";\
	ADDITIONAL_LIB_DIRS="-L$(TOP_DIR)/$(GNUSTEP_OBJ_DIR)";\
	ADDITIONAL_OBJC_LIBS="-lInterfaceBuilder";\
	LD_LIBRARY_PATH="$(TOP_DIR)/$(GNUSTEP_OBJ_DIR):${LD_LIBRARY_PATH}";\
	export ADDITIONAL_INCLUDE_DIRS;\
	export ADDITIONAL_LIB_DIRS;\
	export ADDITIONAL_OBJC_LIBS;\
	export LD_LIBRARY_PATH;\
	if [ "$(DEBUG)" = "" ]; then \
	  gnustep-tests interfacebuilder;\
	else \
	  gnustep-tests --debug interfacebuilder;\
	fi; \
	)

clean::
	-gnustep-tests --clean

include $(GNUSTEP_MAKEFILES)/rules.make
