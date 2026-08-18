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

static void checkGormBundle(NSFileManager *fm, NSString *path)
{
  NSString *infoPath;
  NSString *classesPath;
  NSString *objectsPath;
  NSData *info;
  NSDictionary *classes;
  NSData *objects;
  BOOL hasArchivePrefix;

  passExistingPath(fm, path,
                   [NSString stringWithFormat:
                               @"gorm bundle exists: %@",
                               [path lastPathComponent]]);

  infoPath = [path stringByAppendingPathComponent: @"data.info"];
  classesPath = [path stringByAppendingPathComponent: @"data.classes"];
  objectsPath = [path stringByAppendingPathComponent: @"objects.gorm"];

  info = [NSData dataWithContentsOfFile: infoPath];
  classes = [NSDictionary dictionaryWithContentsOfFile: classesPath];
  objects = [NSData dataWithContentsOfFile: objectsPath];
  hasArchivePrefix = ([info length] >= 15 &&
    [AUTORELEASE([[NSString alloc]
                   initWithData: [info subdataWithRange: NSMakeRange(0, 15)]
                       encoding: NSASCIIStringEncoding])
      isEqual: @"GNUstep archive"]);

  PASS([info length] > 0, "%s data.info can be loaded as data",
       [[path lastPathComponent] cString])
  PASS(hasArchivePrefix, "%s data.info is a GNUstep archive",
       [[path lastPathComponent] cString])
  PASS(classes != nil, "%s data.classes can be parsed",
       [[path lastPathComponent] cString])
  PASS([objects length] > 0, "%s objects.gorm can be loaded as data",
       [[path lastPathComponent] cString])
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *resources;
  NSEnumerator *en;
  NSString *resource;

  START_SET("Gorm application resources")

  resources = [NSArray arrayWithObjects:
    @"GormInfo.plist.in",
    @"Resources/Defaults.plist",
    @"Resources/language-codes.plist",
    @"English.lproj/Gorm.gorm",
    @"English.lproj/GormLanguageViewController.gorm",
    @"English.lproj/Gorm.rtfd",
    @"Images/Gorm.tiff",
    @"Images/GormPalette.tiff",
    @"Images/GormTesting.tiff",
    nil];

  en = [resources objectEnumerator];
  while ((resource = [en nextObject]) != nil)
    {
      passExistingPath(fm, [@"../.." stringByAppendingPathComponent: resource],
                       [NSString stringWithFormat:
                                   @"application resource exists: %@",
                                   resource]);
    }

  PASS([NSDictionary dictionaryWithContentsOfFile:
          @"../../Resources/Defaults.plist"] != nil,
       "Defaults.plist can be parsed as a dictionary")
  PASS([NSDictionary dictionaryWithContentsOfFile:
          @"../../Resources/language-codes.plist"] != nil,
       "language-codes.plist can be parsed as a dictionary")

  checkGormBundle(fm, @"../../English.lproj/Gorm.gorm");
  checkGormBundle(fm,
                  @"../../English.lproj/GormLanguageViewController.gorm");

  END_SET("Gorm application resources")

  RELEASE(pool);
  return 0;
}
