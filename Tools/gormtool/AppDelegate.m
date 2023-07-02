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

@interface ArgPair : NSObject <NSCopying>
{
  NSString *_argument;
  NSString *_value;
}

- (void) setArgument: (NSString *)arg;
- (NSString *) argument;

- (void) setValue: (NSString *)val;
- (NSString *) value;
@end

@implementation ArgPair

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      _argument = nil;
      _value = nil;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_argument);
  RELEASE(_value);

  [super dealloc];
}

- (void) setArgument: (NSString *)arg
{
  ASSIGN(_argument, arg);
}

- (NSString *) argument
{
  return _argument;
}

- (void) setValue: (NSString *)val
{
  ASSIGN(_value, val);
}

- (NSString *) value
{
  return _value;
}

- (id) copyWithZone: (NSZone *)z
{
  id obj = [[[self class] allocWithZone: z] init];

  [obj setArgument: _argument];
  [obj setValue: _value];

  return obj;
}

@end

// AppDelegate...
@implementation AppDelegate

+ (void) initialize
{
  if (__types == nil)
    {
      __types = [NSMutableArray arrayWithCapacity: 10];
    }
}

- (NSDictionary *) parseArguments
{
  GormDocumentController *dc = [GormDocumentController sharedDocumentController];
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  NSArray *args = [pi arguments];
  NSEnumerator *en = [args objectEnumerator];
  id obj = nil;
  BOOL parse_val = NO;
  ArgPair *pair = nil; // [[ArgPair alloc] init];
  
  while ((obj = [en nextObject]) != nil)
    {
      if (parse_val)
	{
	  [pair setValue: obj];
	  [result setObject: pair forKey: [pair argument]];
	  parse_val = NO;
	  continue;
	}
      else
	{
	  pair = [[ArgPair alloc] init];
	  if ([dc typeFromFileExtension: [obj pathExtension]] != nil)
	    {
	      [pair setArgument: @"--read"];
	      [pair setValue: obj];
	      [result setObject: pair forKey: @"--read"];
	    }
	  else if ([obj isEqualToString: @"--write"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }
	  else if ([obj isEqualToString: @"--export-strings-file"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }
	  else if ([obj isEqualToString: @"--import-strings-file"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }
	}
    }

  return result;
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
      NSDictionary *args = [self parseArguments];
      ArgPair *opt = nil;
      
      NSLog(@"args = %@", args);
      NSLog(@"file = %@", file);
      doc = [dc openDocumentWithContentsOfFile: file display: NO];
      NSDebugLog(@"Document = %@", doc);

      // Get the file to write out to...
      NSString *outputFile = file;

      opt = [args objectForKey: @"--write"];
      if (opt != nil)
	{
	  outputFile = [opt value];
	}

      // Get other options...
      opt = [args objectForKey: @"--export-strings-file"];
      if (opt != nil)
	{
	  NSString *stringsFile = [opt value];

	  [doc exportStringsToFile: stringsFile];
	}
      else
	{
	  opt = [args objectForKey: @"--import-strings-file"];

	  if (opt != nil)
	    {
	      NSString *stringsFile = [opt value];
	      
	      [doc importStringsFromFile: stringsFile];
	      [doc saveToFile: outputFile
		saveOperation: NSSaveOperation
		     delegate: nil
		   didSaveSelector: NULL
		  contextInfo: nil];
	    }
	}
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
