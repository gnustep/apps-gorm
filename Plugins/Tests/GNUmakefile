#
# Tests for Gorm plugins.
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
	@(echo If you want to run the Gorm plugin testsuite, please type \'make check\')

check::
	(\
	ADDITIONAL_INCLUDE_DIRS="-I$(TOP_DIR)/..";\
	export ADDITIONAL_INCLUDE_DIRS;\
	if [ "$(DEBUG)" = "" ]; then \
	  gnustep-tests plugins;\
	else \
	  gnustep-tests --debug plugins;\
	fi; \
	)

clean::
	-gnustep-tests --clean

include $(GNUSTEP_MAKEFILES)/rules.make
