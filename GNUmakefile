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
	GormObjCHeaderParser

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
	Resources/GormPrefGuideline.gorm \
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
	GormBoxEditor.h \
	GormClassInspector.h \
	GormClassManager.h \
	GormClassPanelController.h \
	GormColorsPref.h \
	GormControlEditor.h \
	GormCustomClassInspector.h \
	GormCustomView.h \
	GormDocument.h \
	GormFilePrefsManager.h \
	GormFilesOwner.h \
	GormFontViewController.h \
	GormFunctions.h \
	GormGeneralPref.h \
	GormGuidelinePref.h \
	GormHeadersPref.h \
	GormImage.h \
	GormImageInspector.h \
	GormInspectorsManager.h \
	GormInternalViewEditor.h \
	GormMatrixEditor.h \
	GormNSSplitViewInspector.h \
	GormOutlineView.h \
	GormPalettesManager.h \
	GormPalettesPref.h \
	GormPlacementInfo.h \
	GormPrefController.h \
	GormPrivate.h \
	GormResource.h \
	GormScrollViewAttributesInspector.h \
	GormSetNameController.h \
	GormShelfPref.h \
	GormSound.h \
	GormSoundInspector.h \
	GormSoundView.h \
	GormSplitViewEditor.h \
	GormViewEditor.h \
	GormViewKnobs.h \
	GormViewWindow.h \
	GormViewWithContentViewEditor.h \
	GormViewWithSubviewsEditor.h \
	NSColorWell+GormExtensions.h \
	NSFontManager+GormExtensions.h \
	NSView+GormExtensions.h 

Gorm_OBJC_FILES = \
	GModelDecoder.m \
	GormBoxEditor.m \
	GormClassEditor.m \
	GormClassInspector.m \
	GormClassManager.m \
	GormClassPanelController.m \
	GormColorsPref.m \
	GormControlEditor.m \
	GormCustomClassInspector.m \
	GormCustomView.m \
	GormDocument.m \
	GormFilePrefsManager.m \
	GormFilesOwner.m \
	GormFontViewController.m \
	GormFunctions.m \
	GormGeneralPref.m \
	GormGuidelinePref.m \
	GormGenericEditor.m \
	GormHeadersPref.m \
	GormImage.m \
	GormImageEditor.m \
	GormImageInspector.m \
	GormInspectorsManager.m \
	GormInternalViewEditor.m \
	GormMatrixEditor.m \
	GormNSSplitViewInspector.m \
	GormObjectEditor.m \
	GormObjectInspector.m \
	GormOutlineView.m \
	GormPalettesManager.m \
	GormPalettesPref.m \
	GormPrefController.m \
	GormResource.m \
	GormResourceEditor.m \
	GormScrollViewAttributesInspector.m \
	GormScrollViewEditor.m \
	GormSetNameController.m \
	GormShelfPref.m \
	GormSound.m \
	GormSoundEditor.m \
	GormSoundInspector.m \
	GormSoundView.m \
	GormSplitViewEditor.m \
	GormViewEditor.m \
	GormViewKnobs.m \
	GormViewSizeInspector.m \
	GormViewWindow.m \
	GormViewWithContentViewEditor.m \
	GormViewWithSubviewsEditor.m \
	GormWindowEditor.m \
	NSColorWell+GormExtensions.m \
	NSFontManager+GormExtensions.m \
	NSView+GormExtensions.m \
	main.m \
        Gorm.m

-include GNUmakefile.preamble
-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
