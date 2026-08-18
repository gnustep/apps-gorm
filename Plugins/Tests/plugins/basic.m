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

static BOOL sourceContains(NSString *path, NSString *needle)
{
  NSString *source = [NSString stringWithContentsOfFile: path];
  return source != nil && [source rangeOfString: needle].location != NSNotFound;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *pluginDirs;
  NSEnumerator *en;
  NSString *dir;

  START_SET("Gorm plugins")

  PASS((sourceContains(@"../../Gorm/GormGormWrapperBuilder.m",
                       @"GSGormFileType")),
       "the native Gorm plugin declares the Gorm file type")
  PASS((sourceContains(@"../../Nib/GormNibWrapperBuilder.m",
                       @"GSNibFileType")),
       "the nib plugin declares the nib file type")
  PASS((sourceContains(@"../../Xib/GormXibWrapperLoader.m",
                       @"GSXibFileType")),
       "the xib plugin declares the xib file type")
  PASS((sourceContains(@"../../Cib/GormCibWrapperBuilder.m",
                       @"GSCibFileType")),
       "the cib plugin declares the cib file type")

  pluginDirs = [NSArray arrayWithObjects: @"Gorm", @"Nib", @"Xib", @"Cib", nil];
  en = [pluginDirs objectEnumerator];
  while ((dir = [en nextObject]) != nil)
    {
      NSString *path = [@"../.." stringByAppendingPathComponent: dir];
      PASS(([fm fileExistsAtPath:
              [path stringByAppendingPathComponent: @"GNUmakefile"]]),
           "%s has a GNUmakefile", [dir cString])
      PASS(([fm fileExistsAtPath:
              [path stringByAppendingPathComponent:
                      [NSString stringWithFormat: @"Gorm%@Plugin.m", dir]]]),
           "%s has its plugin class source", [dir cString])
    }

  END_SET("Gorm plugins")

  RELEASE(pool);
  return 0;
}
