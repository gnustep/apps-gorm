#
# Tests for gormtool.
#

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before running this!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

all::
	@(echo If you want to run the gormtool testsuite, please type \'make check\')

check::
	(\
	ADDITIONAL_INCLUDE_DIRS="-I../..";\
	export ADDITIONAL_INCLUDE_DIRS;\
	if [ "$(DEBUG)" = "" ]; then \
	  gnustep-tests gormtool;\
	else \
	  gnustep-tests --debug gormtool;\
	fi; \
	)

clean::
	-gnustep-tests --clean

include $(GNUSTEP_MAKEFILES)/rules.make
