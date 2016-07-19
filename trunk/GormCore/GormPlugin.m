/* GormNibModule.m
 *
 * Copyright (C) 2007 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2007
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
 */

#include <Foundation/Foundation.h>
#include <AppKit/NSDocumentController.h>
#include <GormCore/GormPlugin.h>

@interface NSDocumentController (GormPrivate)
- (NSArray *) types;
- (void) setTypes: (NSArray *)types;
- (BOOL) containsDocumentTypeName: (NSString *)tname;
@end

@implementation NSDocumentController (GormPrivate)
- (NSArray *) types
{
  return _types;
}

- (void) setTypes: (NSArray *)types
{
  ASSIGN(_types, types);
}

- (BOOL) containsDocumentTypeName: (NSString *)tname
{
  NSEnumerator *en = [_types objectEnumerator];
  id obj = nil;
  
  while ((obj = [en nextObject]) != nil)
    {
      NSString *name = [obj objectForKey: @"NSName"];
      if([tname isEqualToString: name])
	{
	  return YES;
	}
    }

  return NO;
}
@end


@implementation GormPlugin
- (void) registerDocumentTypeName: (NSString *)name
                humanReadableName: (NSString *)hrName
                    forExtensions: (NSArray *)extensions
{
  NSDocumentController *controller = [NSDocumentController sharedDocumentController];
  NSMutableArray *types = [[controller types] mutableCopy];
  
  if([controller containsDocumentTypeName: name] == NO)
    {
      NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							 name, @"NSName",
						       hrName, @"NSHumanReadableName",
						       extensions, @"NSUnixExtensions",
						       nil];
      [types addObject: dict];
      [controller setTypes: types];
    }
}
@end

