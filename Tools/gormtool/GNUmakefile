#
# GNUmakefile -- gormtool
#

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = gormtool
TOOL_NAME = gormtool

gormtool_HEADER_FILES = 
gormtool_OBJC_FILES = main.m AppDelegate.m

ADDITIONAL_TOOL_LIBS = \
	-lGormObjCHeaderParser \
	-lGormPrefs \
	-lGormCore \
	-IGorm \
	-lgnustep-base \
	-lgnustep-gui

ADDITIONAL_LIB_DIRS = -L../../GormCore/obj \
	-L../../InterfaceBuilder/obj \
	-L../../GormPrefs/obj \
	-L../../GormObjCHeaderParser/obj

ADDITIONAL_INCLUDE_DIRS = -I../../

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble
