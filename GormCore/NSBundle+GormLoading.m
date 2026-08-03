/* NSBundle+GormLoading.m
 *
 * Copyright (C) 2026 Free Software Foundation, Inc.
 *
 * This file is part of GNUstep.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <dlfcn.h>

#import <AppKit/AppKit.h>

#import "NSBundle+GormLoading.h"

typedef NSDictionary *(*GormObjectFactory)(id owner);

@implementation NSBundle (GormLoading)

+ (BOOL) loadGormNamed: (NSString *)name owner: (id)owner
{
  NSString *symbolName = nil;
  GormObjectFactory factory = NULL;
  NSDictionary *objects = nil;
  NSEnumerator *windowEnumerator = nil;
  NSWindow *window = nil;

  if ([name length] == 0)
    {
      return NO;
    }

  symbolName = [NSString stringWithFormat: @"GormCreate%@Objects",
    [self _gormSymbolComponentForName: name]];
  factory = (GormObjectFactory)dlsym(RTLD_DEFAULT, [symbolName cString]);
  if (factory == NULL)
    {
      return NO;
    }

  objects = factory(owner);
  if (objects == nil)
    {
      return NO;
    }

  windowEnumerator = [[objects objectForKey: @"GormVisibleWindows"] objectEnumerator];
  while ((window = [windowEnumerator nextObject]) != nil)
    {
      if ([window isKindOfClass: [NSWindow class]])
        {
          [window orderFront: owner];
        }
    }

  return YES;
}

+ (NSString *) _gormSymbolComponentForName: (NSString *)name
{
  NSMutableString *result = [NSMutableString string];
  NSString *baseName = [[name lastPathComponent] stringByDeletingPathExtension];
  unsigned i = 0;

  for (i = 0; i < [baseName length]; i++)
    {
      unichar ch = [baseName characterAtIndex: i];
      BOOL valid = ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
        || (ch >= '0' && ch <= '9'));

      if (valid == YES)
        {
          [result appendFormat: @"%C", ch];
        }
    }

  if ([result length] == 0)
    {
      [result appendString: @"Interface"];
    }

  {
    unichar firstChar = [result characterAtIndex: 0];
    if (firstChar >= '0' && firstChar <= '9')
      {
        [result insertString: @"Gorm" atIndex: 0];
      }
  }

  return result;
}

@end
