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

static BOOL hasArchivePrefix(NSData *data)
{
  NSString *prefix;

  if ([data length] < 15)
    {
      return NO;
    }

  prefix = AUTORELEASE([[NSString alloc]
                         initWithData:
                           [data subdataWithRange: NSMakeRange(0, 15)]
                             encoding: NSASCIIStringEncoding]);
  return [prefix isEqual: @"GNUstep archive"];
}

static void checkGormBundle(NSString *path)
{
  NSData *info;
  NSDictionary *classes;
  NSData *objects;

  info = [NSData dataWithContentsOfFile:
                   [path stringByAppendingPathComponent: @"data.info"]];
  classes = [NSDictionary dictionaryWithContentsOfFile:
                            [path stringByAppendingPathComponent:
                                    @"data.classes"]];
  objects = [NSData dataWithContentsOfFile:
                      [path stringByAppendingPathComponent: @"objects.gorm"]];

  PASS(hasArchivePrefix(info), "%s data.info is a GNUstep archive",
       [path cString])
  PASS(classes != nil, "%s data.classes can be parsed", [path cString])
  PASS([objects length] > 0, "%s objects.gorm can be loaded as data",
       [path cString])
}

static void checkExample(NSFileManager *fm, NSString *dir, NSArray *sources)
{
  NSEnumerator *en;
  NSString *source;
  NSString *base;

  base = [@"../../Examples" stringByAppendingPathComponent: dir];
  passExistingPath(fm, [base stringByAppendingPathComponent: @"GNUmakefile"],
                   [NSString stringWithFormat: @"%@ has a GNUmakefile", dir]);

  en = [sources objectEnumerator];
  while ((source = [en nextObject]) != nil)
    {
      passExistingPath(fm, [base stringByAppendingPathComponent: source],
                       [NSString stringWithFormat:
                                   @"%@ source exists: %@", dir, source]);
    }

  checkGormBundle([base stringByAppendingPathComponent: @"MainMenu.gorm"]);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSFileManager *fm = [NSFileManager defaultManager];

  START_SET("Documentation resources")

  passExistingPath(fm, @"../../GNUmakefile", @"Documentation has a GNUmakefile");
  passExistingPath(fm, @"../../Gorm.md", @"Gorm.md exists");
  passExistingPath(fm, @"../../readme.texi", @"readme.texi exists");

  checkExample(fm, @"Controller",
               [NSArray arrayWithObjects:
                 @"main.m",
                 @"MyController.h",
                 @"MyController.m",
                 @"WinController.h",
                 @"WinController.m",
                 @"Controller.gorm",
                 nil]);
  checkGormBundle(@"../../Examples/Controller/Controller.gorm");

  checkExample(fm, @"SimpleApp",
               [NSArray arrayWithObjects:
                 @"main.m",
                 @"MyController.h",
                 @"MyController.m",
                 nil]);

  END_SET("Documentation resources")

  RELEASE(pool);
  return 0;
}
