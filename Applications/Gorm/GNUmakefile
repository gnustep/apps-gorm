#   GNUmakefile: main makefile for GNUstep Object Relationship Modeller
#
#   Copyright (C) 1999,2002,2003 Free Software Foundation, Inc.
#
#   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
#   Date: 2003
#   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
#   Date: 1999
#   
#   This file is part of GNUstep.
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(warning )
    $(warning Unable to obtain GNUSTEP_MAKEFILES setting from gnustep-config!)
    $(warning Perhaps gnustep-make is not properly installed,)
    $(warning so gnustep-config is not in your PATH.)
    $(warning )
    $(warning Your PATH is currently $(PATH))
    $(warning )
  endif
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

PACKAGE_NAME = gorm
export PACKAGE_NAME
include $(GNUSTEP_MAKEFILES)/common.make

CVS_MODULE_NAME = gorm
SVN_MODULE_NAME = gorm
SVN_BASE_URL = svn+ssh://svn.gna.org/svn/gnustep/apps


include ./Version

#
# Each palette is a subproject
#
SUBPROJECTS = \
	Palettes

#
# MAIN APP
#
APP_NAME = Gorm
Gorm_PRINCIPAL_CLASS=Gorm
Gorm_APPLICATION_ICON=Gorm.tiff
Gorm_RESOURCE_FILES = \
	GormInfo.plist \
	Resources/ClassInformation.plist \
	Resources/VersionProfiles.plist \
	Resources/Defaults.plist \
	Palettes/0Menus/0Menus.palette \
	Palettes/1Windows/1Windows.palette \
	Palettes/2Controls/2Controls.palette \
	Palettes/3Containers/3Containers.palette \
	Palettes/4Data/4Data.palette \
	Images/FileIcon_gmodel.tiff \
	Images/GormEHCoil.tiff \
	Images/GormEHLine.tiff \
	Images/GormEVCoil.tiff \
	Images/GormEVLine.tiff \
	Images/GormFile.tiff \
	Images/GormMenu.tiff \
	Images/GormMHCoil.tiff \
	Images/GormMHLine.tiff \
	Images/GormMVCoil.tiff \
	Images/GormMVLine.tiff \
	Images/GormNib.tiff \
	Images/GormPalette.tiff \
        Images/Gorm.tiff \


Gorm_LOCALIZED_RESOURCE_FILES = \
	GormDocument.gorm \
	Gorm.gorm \
	GormInconsistenciesPanel.gorm \
	GormPalettePanel.gorm \
	GormPrefColors.gorm \
	GormPreferences.gorm \
	GormPrefGeneral.gorm \
	GormPrefGuideline.gorm \
	GormPrefHeaders.gorm \
	GormPrefPalettes.gorm \
	GormPrefPlugins.gorm \
	GormShelfPref.gorm \
	Gorm.rtfd

Gorm_LANGUAGES = \
	English

Gorm_HEADERS = 

Gorm_OBJC_FILES = \
	Gorm.m \
	main.m 

-include GNUmakefile.preamble
-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/Master/nsis.make
