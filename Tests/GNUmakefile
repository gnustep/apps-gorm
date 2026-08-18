#
# Tests aggregate for Gorm.
#

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before running this!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECTS = \
	../InterfaceBuilder/Tests \
	../GormObjCHeaderParser/Tests \
	../GormCore/Tests \
	../Plugins/Tests \
	../Applications/Gorm/Tests \
	../Applications/Gorm/Palettes/Tests \
	../Tools/gormtool/Tests \
	../Scripts/Tests

all::
	@(echo If you want to run the Gorm testsuite, please type \'make check\')

check clean::
	@for d in $(SUBPROJECTS); do \
	  $(MAKE) -C $$d $@ || exit $$?; \
	done

include $(GNUSTEP_MAKEFILES)/rules.make
