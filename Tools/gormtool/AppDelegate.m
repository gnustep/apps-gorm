/* AppDelegate.m
 *
 * Copyright (C) 2023 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2023
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111
 * USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormPlugin.h>
#import <GormCore/GormDocumentController.h>

#import <GNUstepGUI/GSNibLoading.h>

#import "AppDelegate.h"

static NSMutableArray *__types = nil;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-protocol-method-implementation"

// Special method category smashes so that we can register types...

@implementation NSDocumentController (ToolPrivate)

- (Class) documentClassForType: (NSString *)type
{
  return [GormDocument class];
}

- (NSString *) typeFromFileExtension: (NSString *)fileExtension
{
  int i, count = [__types count];

  // Check for a document type with the supplied extension
  for (i = 0; i < count; i++)
    {
      NSDictionary *typeInfo = [__types objectAtIndex: i];
      NSArray *array = [typeInfo objectForKey: @"NSUnixExtensions"];

      NSDebugLog(@"typeInfo = %@", typeInfo);
      NSDebugLog(@"fileExtension = %@", fileExtension);
      
      if ([array containsObject: fileExtension])
	{
	  NSString *type = [typeInfo objectForKey: @"NSName"];
	  NSDebugLog(@"type = %@", type);
	  return type;
	}
    }

  NSDebugLog(@"FAILED");
  return nil;
}

@end

@implementation GormPlugin (ToolPrivate)

- (void) registerDocumentTypeName: (NSString *)name
                humanReadableName: (NSString *)hrName
                    forExtensions: (NSArray *)extensions
{
  if (__types == nil)
    {
      __types = [NSMutableArray arrayWithCapacity: 10];
    }
  
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						     name, @"NSName",
						   hrName, @"NSHumanReadableName",
						   extensions, @"NSUnixExtensions",
						   nil];
  [__types addObject: dict];

  NSDebugLog(@"__types = %@", __types);
}

@end

#pragma GCC diagnostic pop

// AppDelegate...
@implementation AppDelegate

+ (void) initialize
{
  if (__types == nil)
    {
      __types = [NSMutableArray arrayWithCapacity: 10];
    }
}

- (void) process
{
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  
  [NSClassSwapper setIsInInterfaceBuilder: YES];

  NSLog(@"Processing... %@", [pi arguments]);

  if ([[pi arguments] count] > 1)
    {
      NSString *file = [[pi arguments] objectAtIndex: 1];
      GormDocumentController *dc = [GormDocumentController sharedDocumentController];
      GormDocument *doc = nil;
      
      NSLog(@"file = %@", file);
      doc = [dc openDocumentWithContentsOfFile: file display: NO];
      NSLog(@"Document = %@", doc);
    }
  
  [NSClassSwapper setIsInInterfaceBuilder: NO];
}

- (void) applicationDidFinishLaunching: (NSNotification *)n
{
  puts("== gormtool");
  
  NSLog(@"processInfo: %@", [NSProcessInfo processInfo]);
  [self process];
 
  [NSApp terminate: nil];
}

- (void) applicationWillTerminate: (NSNotification *)n
{
  puts("== finished...");
}

@end
