#
# GNUmakefile 
# Written by Gregory John Casamento <greg_casamento@yahoo.com>
#
# NOTE: Do NOT change this file -- ProjectCenter maintains it!
#
# Put all of your customisations in GNUmakefile.preamble and
# GNUmakefile.postamble
#

include $(GNUSTEP_MAKEFILES)/common.make


#
# Subprojects
#



#
# Framework
#

PACKAGE_NAME=GormPrefs
LIBRARY_VAR=GORMPREFS
LIBRARY_NAME=GormPrefs

GormPrefs_HEADER_FILES_DIR=.
GormPrefs_HEADER_FILES_INSTALL_DIR=/GormPrefs
ADDITIONAL_INCLUDE_DIRS = -I..
srcdir = .

include ../Version

#
# Additional libraries
#

GormPrefs_LIBRARIES_DEPEND_UPON += -lgnustep-gui -l$(FOUNDATION_LIBRARY_NAME)

#
# Header files
#

GormPrefs_HEADER_FILES= \
GormColorsPref.h \
GormGeneralPref.h \
GormGuidelinePref.h \
GormHeadersPref.h \
GormPalettesPref.h \
GormPrefController.h \
GormShelfPref.h

#
# Class files
#

GormPrefs_OBJC_FILES= \
GormColorsPref.m \
GormGeneralPref.m \
GormGuidelinePref.m \
GormHeadersPref.m \
GormPalettesPref.m \
GormPrefController.m \
GormShelfPref.m

#
# Resources
#
#GormPrefs_LOCALIZED_RESOURCE_FILES= \
#GormPrefColors.gorm \
#GormPreferences.gorm \
#GormPrefGeneral.gorm \
#GormPrefGuideline.gorm \
#GormPrefHeaders.gorm \
#GormPrefPalettes.gorm \
#GormShelfPref.gorm

#
# Languages
#
#GormPrefs_LANGUAGES= \
#English

#
# C files
#

GormPrefs_C_FILES= 

HEADERS_INSTALL = $(GormPrefs_HEADER_FILES)

-include GNUmakefile.preamble
-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble
