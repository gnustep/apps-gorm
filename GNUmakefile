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
	GormLib \
	Palettes \
	GormObjCHeaderParser \
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
	VersionProfiles.plist \
	Defaults.plist \
	Palettes/0Menus/0Menus.palette \
	Palettes/1Windows/1Windows.palette \
	Palettes/2Controls/2Controls.palette \
	Palettes/3Containers/3Containers.palette \
	Palettes/4Data/4Data.palette \
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
        Images/Gorm.tiff \
        Images/leftalign_nib.tiff \
        Images/rightalign_nib.tiff \
        Images/centeralign_nib.tiff \
        Images/justifyalign_nib.tiff \
        Images/naturalalign_nib.tiff \
	Images/iconAbove_nib.tiff \
	Images/iconBelow_nib.tiff \
	Images/iconLeft_nib.tiff \
	Images/iconOnly_nib.tiff \
	Images/iconRight_nib.tiff \
	Images/titleOnly_nib.tiff \
	Images/line_nib.tiff \
	Images/bezel_nib.tiff \
	Images/noBorder_nib.tiff \
	Images/ridge_nib.tiff \
	Images/button_nib.tiff \
	Images/shortbutton_nib.tiff \
	Images/photoframe_nib.tiff \
	Images/date_formatter.tiff \
	Images/number_formatter.tiff \
	Images/Sunday_seurat.tiff \
	Images/iconBottomLeft_nib.tiff \
	Images/iconBottomRight_nib.tiff \
	Images/iconBottom_nib.tiff \
	Images/iconCenterLeft_nib.tiff \
	Images/iconCenterRight_nib.tiff \
	Images/iconCenter_nib.tiff \
	Images/iconTopLeft_nib.tiff \
	Images/iconTopRight_nib.tiff \
	Images/iconTop_nib.tiff \
	Images/GormAction.tiff \
	Images/GormOutlet.tiff \
	Images/GormActionSelected.tiff \
	Images/GormOutletSelected.tiff \
	Images/FileIcon_gmodel.tiff \
	Images/tabtop_nib.tiff \
	Images/tabbot_nib.tiff \
	Images/GormView.tiff \
	Images/LeftArr.tiff \
	Images/RightArr.tiff \
	Images/GormTesting.tiff \
	Resources/GormClassPanel.gorm \
	Resources/GormPrefColors.gorm \
	Resources/GormViewSizeInspector.gorm \
	Resources/GormCustomClassInspector.gorm \
	Resources/GormSoundInspector.gorm \
	Resources/GormImageInspector.gorm \
	Resources/GormPreferences.gorm \
	Resources/GormPrefHeaders.gorm \
	Resources/GormPrefGeneral.gorm \
	Resources/GormPrefPalettes.gorm \
	Resources/GormShelfPref.gorm \
	Resources/GormScrollViewAttributesInspector.gorm \
	Resources/GormNSSplitViewInspector.gorm \
	Resources/GormClassInspector.gorm \
	Resources/GormFontView.gorm \
	Resources/GormSetName.gorm \
	Resources/GormDocument.gorm \
	Resources/Gorm.gorm

Gorm_HEADERS = \
	Gorm.h \
	GormPrivate.h \
	GormCustomView.h \
	GormOutlineView.h \
	GormBoxEditor.h \
	GormCustomClassInspector.h \
	GormScrollViewAttributesInspector.h \
	GormNSSplitViewInspector.h \
	GormSoundInspector.h \
	GormImageInspector.h \
	GormMatrixEditor.h \
	GormPalettesManager.h \
	GormViewEditor.h \
	GormViewWithSubviewsEditor.h \
	GormViewWithContentViewEditor.h \
	GormViewWindow.h \
	GormViewKnobs.h \
	GormClassManager.h \
	GormControlEditor.h \
	GormDocument.h \
	GormFilesOwner.h \
	GormInspectorsManager.h \
	GormInternalViewEditor.h \
	GormSplitViewEditor.h \
	GormPlacementInfo.h \
	GormPrefController.h\
	GormHeadersPref.h \
	GormClassInspector.h \
	GormFontViewController.h \
	GormSetNameController.h \
	GormGeneralPref.h \
	GormFunctions.h \
	GormShelfPref.h \
	GormColorsPref.h \
	GormPalettesPref.h \
	GormSoundView.h \
	GormFilePrefsManager.h \
	GormClassPanelController.h \
	NSView+GormExtensions.h \
	GormSound.h \
	GormImage.h

Gorm_OBJC_FILES = \
	main.m \
        Gorm.m \
	GormDocument.m \
	GModelDecoder.m \
	GormBoxEditor.m \
	GormCustomView.m \
	GormViewKnobs.m \
	GormFilesOwner.m \
	GormClassEditor.m \
	GormMatrixEditor.m \
	GormGenericEditor.m \
	GormObjectEditor.m \
	GormObjectInspector.m \
	GormViewSizeInspector.m \
	GormScrollViewAttributesInspector.m \
	GormNSSplitViewInspector.m \
	GormWindowEditor.m \
	GormClassManager.m \
	GormInspectorsManager.m \
	GormViewEditor.m \
	GormViewWithSubviewsEditor.m \
	GormViewWithContentViewEditor.m \
	GormViewWindow.m \
	GormControlEditor.m \
	GormSplitViewEditor.m \
	GormInternalViewEditor.m \
	GormPalettesManager.m \
	GormOutlineView.m \
	GormCustomClassInspector.m \
	GormSoundInspector.m \
	GormImageInspector.m \
	GormScrollViewEditor.m \
	GormImageEditor.m \
	GormSoundEditor.m \
	GormPrefController.m \
	GormHeadersPref.m \
	GormClassInspector.m \
	GormFontViewController.m \
	GormSetNameController.m \
	GormGeneralPref.m \
	GormFunctions.m \
	GormShelfPref.m \
	GormColorsPref.m \
	GormPalettesPref.m \
	GormSoundView.m \
	GormFilePrefsManager.m \
	GormClassPanelController.m \
	NSView+GormExtensions.m \
	GormSound.m \
	GormImage.m

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
