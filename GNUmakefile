#   GNUmakefile: main makefile for GNUstep Object Relationship Modeller
#
#   Copyright (C) 1999 Free Software Foundation, Inc.
#
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
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA
#

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME=Gorm
include ./Version

#
# Each palette is a subproject
#
SUBPROJECTS = \
	Palettes \
	Testing

#
# MAIN APP
#
APP_NAME = Gorm
Gorm_PRINCIPAL_CLASS=Gorm
Gorm_APPLICATION_ICON=Gorm.tiff
Gorm_RESOURCE_FILES = \
	GormInfo.plist \
	ClassInformation.plist \
	Defaults.plist \
	Palettes/0Menus/0Menus.palette \
	Palettes/1Windows/1Windows.palette \
	Palettes/2Controls/2Controls.palette \
	Palettes/3Containers/3Containers.palette \
	Images/GormClass.tiff \
	Images/GormFilesOwner.tiff \
	Images/GormFirstResponder.tiff \
	Images/GormFontManager.tiff \
	Images/GormImage.tiff \
	Images/GormWindow.tiff \
	Images/GormMenu.tiff \
	Images/GormObject.tiff \
	Images/GormSound.tiff \
	Images/GormUnknown.tiff \
	Images/GormSourceTag.tiff \
	Images/GormTargetTag.tiff \
	Images/GormLinkImage.tiff \
	Images/GormEHCoil.tiff \
	Images/GormEHLine.tiff \
	Images/GormEVCoil.tiff \
	Images/GormEVLine.tiff \
	Images/GormMHCoil.tiff \
	Images/GormMHLine.tiff \
	Images/GormMVCoil.tiff \
	Images/GormMVLine.tiff \
        Images/Gorm.tiff

Gorm_HEADERS = \
	Gorm.h \
	GormPrivate.h

Gorm_OBJC_FILES = \
        Gorm.m \
	GormDocument.m \
	IBInspector.m \
	IBPalette.m \
	GormViewKnobs.m \
	GormFilesOwner.m \
	GormClassEditor.m \
	GormObjectEditor.m \
	GormObjectInspector.m \
	GormWindowEditor.m \
	GormClassManager.m \
	GormInspectorsManager.m \
	GormPalettesManager.m

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble

