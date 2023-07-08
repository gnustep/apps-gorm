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

#import "ArgPair.h"
#import "GormToolPrivate.h"
#import "AppDelegate.h"

// AppDelegate...
@implementation AppDelegate

- (BOOL) isInTool
{
  return YES;
}

- (NSDictionary *) parseArguments
{
  GormDocumentController *dc = [GormDocumentController sharedDocumentController];
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  NSMutableArray *args = [NSMutableArray arrayWithArray: [pi arguments]];
  BOOL filenameIsLastObject = NO;
  NSString *file = nil;

  // If the --read option isn't specified, we assume that the last argument is
  // the file to be processed.
  if ([args containsObject: @"--read"] == NO)
    {
      file = [args lastObject];
      filenameIsLastObject = YES;
      [args removeObject: file];
    }
  
  NSEnumerator *en = [args objectEnumerator];
  id obj = nil;
  BOOL parse_val = NO;
  ArgPair *pair = AUTORELEASE([[ArgPair alloc] init]);
  
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
	  pair = AUTORELEASE([[ArgPair alloc] init]);
	  if (filenameIsLastObject == YES)
	    {
	      NSString  *type = [dc typeFromFileExtension: [file pathExtension]];

	      if (type != nil)
		{
		  [pair setArgument: @"--read"];
		  [pair setValue: file];
		  [result setObject: pair forKey: @"--read"];
		}
	    }
	  else if ([obj isEqualToString: @"--read"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;	      
	    }

	  if ([obj isEqualToString: @"--write"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }

	  if ([obj isEqualToString: @"--export-strings-file"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }

	  if ([obj isEqualToString: @"--import-strings-file"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }

	  if ([obj isEqualToString: @"--export-class"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }
	  
	  if ([obj isEqualToString: @"--import-class"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }

	  if ([obj isEqualToString: @"--output-path"])
	    {
	      [pair setArgument: obj];
	      parse_val = YES;
	    }

	  if ([obj isEqualToString: @"--connections"])
	    {
	      [pair setArgument: obj];
	      parse_val = NO;
	    }

	  if ([obj isEqualToString: @"--classes"])
	    {
	      [pair setArgument: obj];
	      parse_val = NO;
	    }

	  if ([obj isEqualToString: @"--objects"])
	    {
	      [pair setArgument: obj];
	      parse_val = NO;
	    }

	  if ([obj isEqualToString: @"--errors"])
	    {
	      [pair setArgument: obj];
	      parse_val = NO;
	    }

	  if ([obj isEqualToString: @"--warnings"])
	    {
	      [pair setArgument: obj];
	      parse_val = NO;
	    }

	  if ([obj isEqualToString: @"--notices"])
	    {
	      [pair setArgument: obj];
	      parse_val = NO;
	    }

	  // If there is no parameter for the argument, set it anyway...
	  if (parse_val == NO)
	    {
	      [result setObject: pair forKey: obj];
	    }
	}
    }

  return result;
}

- (void) process
{
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  
  [NSClassSwapper setIsInInterfaceBuilder: YES];

  if ([[pi arguments] count] > 1)
    {
      NSString *file = nil;
      NSString *outputPath = @"./";
      GormDocumentController *dc = [GormDocumentController sharedDocumentController];
      GormDocument *doc = nil;
      NSDictionary *args = [self parseArguments];
      ArgPair *opt = nil;
      
      NSDebugLog(@"args = %@", args);
      NSDebugLog(@"file = %@", file);

      // Get the file to write out to...
      NSString *outputFile = nil;

      opt = [args objectForKey: @"--read"];
      if (opt != nil)
	{
	  file = [opt value];
	}

      if (file != nil)
	{
	  doc = [dc openDocumentWithContentsOfFile: file display: NO];
	  if (doc == nil)
	    {
	      NSLog(@"Unable to load document %@", file);
	      return;
	    }
	}
      else
	{
	  NSLog(@"No document specified");
	  return;
	}
      
      NSDebugLog(@"Document = %@", doc);

      // Get other options...
      opt = [args objectForKey: @"--output-path"];
      if (opt != nil)
	{
	  outputPath = [opt value];
	}
      
      opt = [args objectForKey: @"--export-strings-file"];
      if (opt != nil)
	{
	  NSString *stringsFile = [opt value];

	  [doc exportStringsToFile: stringsFile];
	}

      opt = [args objectForKey: @"--import-strings-file"];
      if (opt != nil)
	{
	  NSString *stringsFile = [opt value];
	  
	  [doc importStringsFromFile: stringsFile];
	}

      opt = [args objectForKey: @"--export-class"];
      if (opt != nil)
	{
	  NSString *className = [opt value];
	  BOOL saved = NO;
	  GormClassManager *cm = [doc classManager];
	  NSString *hFile = [className stringByAppendingPathExtension: @"h"];
	  NSString *mFile = [className stringByAppendingPathExtension: @"m"];
	  NSString *hPath = [outputPath stringByAppendingPathComponent: hFile];
	  NSString *mPath = [outputPath stringByAppendingPathComponent: mFile];
	  
	  saved = [cm makeSourceAndHeaderFilesForClass: className
					      withName: mPath
						   and: hPath];
	  
	  if (saved == NO)
	    {
	      NSLog(@"Class named %@ not saved", className);
	    }
	}

      opt = [args objectForKey: @"--import-class"];
      if (opt != nil)
	{
	  NSString *classFile = [opt value];
	  GormClassManager *cm = [doc classManager];
	  
	  [cm parseHeader: classFile];
	}


      opt = [args objectForKey: @"--connections"];
      if (opt != nil)
	{
	  NSArray *connections = [doc connections];
	  puts([[NSString stringWithFormat: @"%@", connections] cStringUsingEncoding: NSUTF8StringEncoding]);
	}

      opt = [args objectForKey: @"--classes"];
      if (opt != nil)
	{
	  NSDictionary *classes = [[doc classManager] customClassInformation];
	  puts([[NSString stringWithFormat: @"%@", classes] cStringUsingEncoding: NSUTF8StringEncoding]);
	}

      opt = [args objectForKey: @"--objects"];
      if (opt != nil)
	{
	  NSSet *objects = [doc topLevelObjects];
	  puts([[NSString stringWithFormat: @"%@", objects] cStringUsingEncoding: NSUTF8StringEncoding]);
	}

      opt = [args objectForKey: @"--errors"];
      if (opt != nil)
	{
	  GormFilePrefsManager *mgr = [doc filePrefsManager];
	  NSDictionary *p = [NSDictionary dictionaryWithDictionary: [mgr currentProfile]];
	  puts([[NSString stringWithFormat: @"%@", p] cStringUsingEncoding: NSUTF8StringEncoding]);
	}

      opt = [args objectForKey: @"--warnings"];
      if (opt != nil)
	{
	  GormFilePrefsManager *mgr = [doc filePrefsManager];
	  NSDictionary *p = [NSDictionary dictionaryWithDictionary: [mgr currentProfile]];
	  puts([[NSString stringWithFormat: @"%@", p] cStringUsingEncoding: NSUTF8StringEncoding]);
	}

      opt = [args objectForKey: @"--notices"];
      if (opt != nil)
	{
	  GormFilePrefsManager *mgr = [doc filePrefsManager]; 
	  NSDictionary *p = [NSDictionary dictionaryWithDictionary: [mgr currentProfile]];
	  puts([[NSString stringWithFormat: @"%@", p] cStringUsingEncoding: NSUTF8StringEncoding]);
	}

      // These options sound always be processed last...
      opt = [args objectForKey: @"--write"];
      if (opt != nil)
	{
	  outputFile = [opt value];
	  if (outputFile != nil)
	    {	  
	      BOOL saved = NO;
	      NSURL *file = [NSURL fileURLWithPath: outputFile isDirectory: YES];
	      NSString *type = [dc typeFromFileExtension: [outputFile pathExtension]];
	      NSError *error = nil;
	      
	      saved = [doc saveToURL: file
			      ofType: type
			   forSaveOperation: NSSaveOperation
			       error: &error];
	      if (!saved)
		{
		  NSLog(@"Document %@ of type %@ was not saved", file, type);
		}
	      
	      if (error != nil)
		{
		  NSLog(@"Error = %@", error);
		}
	    }
	}
    }
  
  [NSClassSwapper setIsInInterfaceBuilder: NO];
}

- (void) applicationDidFinishLaunching: (NSNotification *)n
{
  // puts("== gormtool");
  
  NSDebugLog(@"processInfo: %@", [NSProcessInfo processInfo]);
  [self process];
 
  [NSApp terminate: nil];
}

- (void) applicationWillTerminate: (NSNotification *)n
{
  // puts("== finished...");
}

@end
