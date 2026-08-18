#
# Tests for documentation resources and examples.
#

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before running this!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

all::
	@(echo If you want to run the Documentation testsuite, please type \'make check\')

check::
	(\
	if [ "$(DEBUG)" = "" ]; then \
	  gnustep-tests documentation;\
	else \
	  gnustep-tests --debug documentation;\
	fi; \
	)

clean::
	-gnustep-tests --clean

include $(GNUSTEP_MAKEFILES)/rules.make
