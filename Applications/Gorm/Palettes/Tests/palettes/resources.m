/*
 * Copyright (C) 2026 Free Software Foundation, Inc.
 *
 * This file is part of GNUstep.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */

#import "Testing.h"
#import <Foundation/Foundation.h>

static void passExistingPath(NSFileManager *fm, NSString *path, NSString *label)
{
  PASS([fm fileExistsAtPath: path], "%s", [label cString])
}

static void checkGormBundle(NSString *path)
{
  NSData *info;
  NSDictionary *classes;
  NSData *objects;
  BOOL hasArchivePrefix;

  info = [NSData dataWithContentsOfFile:
                   [path stringByAppendingPathComponent: @"data.info"]];
  classes = [NSDictionary dictionaryWithContentsOfFile:
                            [path stringByAppendingPathComponent:
                                    @"data.classes"]];
  objects = [NSData dataWithContentsOfFile:
                      [path stringByAppendingPathComponent: @"objects.gorm"]];
  hasArchivePrefix = ([info length] >= 15 &&
    [AUTORELEASE([[NSString alloc]
                   initWithData: [info subdataWithRange: NSMakeRange(0, 15)]
                       encoding: NSASCIIStringEncoding])
      isEqual: @"GNUstep archive"]);

  PASS([info length] > 0, "%s data.info can be loaded as data", [path cString])
  PASS(hasArchivePrefix, "%s data.info is a GNUstep archive", [path cString])
  PASS(classes != nil, "%s data.classes can be parsed", [path cString])
  PASS([objects length] > 0, "%s objects.gorm can be loaded as data",
       [path cString])
}

static void checkPalette(NSFileManager *fm, NSString *dir, NSArray *resources)
{
  NSEnumerator *en;
  NSString *resource;
  NSString *base;

  base = [@"../.." stringByAppendingPathComponent: dir];
  passExistingPath(fm, [base stringByAppendingPathComponent: @"GNUmakefile"],
                   [NSString stringWithFormat: @"%@ has a GNUmakefile", dir]);
  passExistingPath(fm, [base stringByAppendingPathComponent: @"palette.table"],
                   [NSString stringWithFormat: @"%@ has palette.table", dir]);

  en = [resources objectEnumerator];
  while ((resource = [en nextObject]) != nil)
    {
      passExistingPath(fm, [base stringByAppendingPathComponent: resource],
                       [NSString stringWithFormat:
                                   @"%@ resource exists: %@", dir, resource]);
      if ([[resource pathExtension] isEqual: @"gorm"])
        {
          checkGormBundle([base stringByAppendingPathComponent: resource]);
        }
    }
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSFileManager *fm = [NSFileManager defaultManager];

  START_SET("Gorm palette resources")

  checkPalette(fm, @"0Menus",
               [NSArray arrayWithObjects:
                 @"MenusPalette.tiff",
                 @"GormMenuDrag.tiff",
                 @"GormMenuAttributesInspector.gorm",
                 @"GormMenuItemAttributesInspector.gorm",
                 nil]);
  checkPalette(fm, @"1Windows",
               [NSArray arrayWithObjects:
                 @"WindowsPalette.tiff",
                 @"WindowDrag.tiff",
                 @"Drawer.tiff",
                 @"DrawerSmall.tiff",
                 @"GormNSWindowInspector.gorm",
                 @"GormDrawerAttributesInspector.gorm",
                 nil]);
  checkPalette(fm, @"2Controls",
               [NSArray arrayWithObjects:
                 @"ControlsPalette.tiff",
                 @"ControlsPalette.gorm",
                 @"GormNSButtonInspector.gorm",
                 @"GormNSCellInspector.gorm",
                 @"GormNSColorWellInspector.gorm",
                 @"GormNSFormInspector.gorm",
                 @"GormNSMatrixInspector.gorm",
                 @"GormNSPopUpButtonInspector.gorm",
                 @"GormNSSliderInspector.gorm",
                 @"GormNSStepperInspector.gorm",
                 @"GormNSTextFieldInspector.gorm",
                 nil]);
  checkPalette(fm, @"3Containers",
               [NSArray arrayWithObjects:
                 @"ContainersPalette.tiff",
                 @"GormNSBrowserInspector.gorm",
                 @"GormNSTableColumnInspector.gorm",
                 @"GormNSTableColumnSizeInspector.gorm",
                 @"GormNSTableViewInspector.gorm",
                 @"GormTabViewInspector.gorm",
                 nil]);
  checkPalette(fm, @"4Data",
               [NSArray arrayWithObjects:
                 @"DataPalette.tiff",
                 @"GormNSDateFormatterInspector.gorm",
                 @"GormNSComboBoxInspector.gorm",
                 @"GormNSImageViewInspector.gorm",
                 @"GormNSNumberFormatterInspector.gorm",
                 @"GormNSTextViewInspector.gorm",
                 nil]);
  checkPalette(fm, @"5Toolbar",
               [NSArray arrayWithObjects:
                 @"ToolbarPalette.tiff",
                 @"ToolbarPalette.gorm",
                 @"GormToolbarAttributesInspector.gorm",
                 nil]);
  checkPalette(fm, @"6Formatters",
               [NSArray arrayWithObjects:
                 @"Resources/FormatterPalette.tiff",
                 @"Resources/FormatterPalette.gorm",
                 @"Resources/GormByteCountFormatterInspector.gorm",
                 @"Resources/GormDateComponentsFormatterInspector.gorm",
                 @"Resources/GormDateIntervalFormatterInspector.gorm",
                 @"Resources/GormEnergyFormatterInspector.gorm",
                 @"Resources/GormISO8601DateFormatterInspector.gorm",
                 @"Resources/GormLengthFormatterInspector.gorm",
                 @"Resources/GormMassFormatterInspector.gorm",
                 @"Resources/GormMeasurementFormatterInspector.gorm",
                 @"Resources/GormPersonNameComponentsFormatterInspector.gorm",
                 nil]);

  END_SET("Gorm palette resources")

  RELEASE(pool);
  return 0;
}
