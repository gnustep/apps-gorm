/* GormNibWrapperLoader
 *
 * Copyright (C) 2010 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2010
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include <GormCore/GormPalettesManager.h>
#include <GormCore/GormClassManager.h>
#include <GormCore/GormImage.h>
#include <GormCore/GormSound.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/NSView+GormExtensions.h>
#include <GormCore/GormFunctions.h>
#include <GormCore/GormCustomView.h>

#include "GormXibWrapperLoader.h"
// #include "GormWindowTemplate.h"

@interface IBObjectRecord (GormLoading)
- (id) parent;
@end

@implementation IBObjectRecord (GormLoading)
- (id) parent
{
  return parent;
}
@end

@interface IBConnectionRecord (GormLoading)
- (IBConnection *) connection;
@end

@implementation IBConnectionRecord (GormLoading)
- (IBConnection *) connection
{
  return connection;
}
@end

@interface IBConnection (GormLoading)
- (NSString *) label;
- (id) source;
- (id) destination;

// - (void) setLabel: (NSString *)string;
// - (void) setSource: (id)src;
// - (void) setDestination: (id)dst;

- (NSNibConnector *) nibConnector;

@end

@implementation IBConnection (GormLoading)
- (NSString *) label
{
  return label;
}

- (id) source
{
  return source;
}

- (id) destination
{
  return destination;
}

// - (void) setLabel: (NSString *)string;
// - (void) setSource: (id)src;
// - (void) setDestination: (id)dst;

- (NSNibConnector *) nibConnector
{
  NSString *tag = [self label];
  NSRange colonRange = [tag rangeOfString: @":"];
  unsigned int location = colonRange.location;
  NSNibConnector *result = nil;

  if(location == NSNotFound)
    {
      result = [[NSNibOutletConnector alloc] init];
    }
  else
    {
      result = [[NSNibControlConnector alloc] init];
    }

  [result setDestination: [self destination]];
  [result setSource: [self source]];
  [result setLabel: [self label]];
  
  return result;
}
@end

@interface IBObjectContainer (GormLoading)
- (NSEnumerator *) connectionRecordEnumerator;
@end

@implementation IBObjectContainer (GormLoading)
- (NSEnumerator *) connectionRecordEnumerator
{
  return [connectionRecords objectEnumerator];
}
@end

@interface GSXibKeyedUnarchiver (GormLoading)
- (id) objectForKey: (id)key;
@end

@implementation GSXibKeyedUnarchiver (GormLoading)
- (id) objectForKey: (id)key
{
  return [decoded objectForKey: key];
}
@end

@class GormNSWindow;

@implementation GormXibWrapperLoader
+ (NSString *) fileType
{
  return @"GSXibFileType";
}

- (BOOL) isTopLevelObject: (id)obj
{
  NSEnumerator *en = [container objectRecordEnumerator];
  IBObjectRecord *objectRecord = nil;

  // Iterate through the list of objects... 
  // if there is no parent for a given object then it is a top level object.
  while((objectRecord = [en nextObject]) != nil)
    {
      id object = [objectRecord object];
      if(object == obj)
	{
	  id parent = [objectRecord parent];
	  if(parent == nil)
	    {
	      return YES;
	    }
	}
    }

  return NO;
}

- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *) doc
{
  BOOL result = NO;

  NS_DURING
    {
      // NSData                    *classes = nil;
      // NSString                  *key = nil;
      GormPalettesManager       *palettesManager = [(id<Gorm>)NSApp palettesManager];
      NSDictionary              *substituteClasses = [palettesManager substituteClasses];
      NSString                  *subClassName = nil;
      // NSDictionary              *fileWrappers = nil;

      if ([super loadFileWrapper: wrapper 
		 withDocument: doc] &&
	  [wrapper isDirectory] == NO)
	{
	  // NSString *path = [[wrapper filename] stringByDeletingLastPathComponent];
	  NSData *data = [wrapper regularFileContents];
	  GormClassManager *classManager = [document classManager];
	  id docFilesOwner;

	  // turn off custom classes...
	  /*
	  [NSClassSwapper setIsInInterfaceBuilder: YES];	  
	  en = [fileWrappers keyEnumerator];
	  while((key = [en nextObject]) != nil)
	    {
	      NSFileWrapper *fw = [fileWrappers objectForKey: key];
	      if([fw isRegularFile])
		{
		  NSData *fileData = [fw regularFileContents];
		  if([key isEqual: @"keyedobjects.nib"])
		    {
		      data = fileData;
		    }
		  else if([key isEqual: @"classes.nib"])
		    {
		      classes = fileData;
		      
		      // load the custom classes...
		      if (![classManager loadXibFormatCustomClassesWithData: classes]) 
			{
			  NSRunAlertPanel(_(@"Problem Loading"), 
					  _(@"Could not open the associated classes file.\n"
					    @"You won't be able to edit connections on custom classes"), 
					  _(@"OK"), nil, nil);
			}
		    }
		}
	    }
	  */
	  
	  // check the data...
	  if (data == nil) 
	    {
	      result = NO;
	    }
	  else
	    {
	      NSEnumerator *en;
	      //
	      // Create an unarchiver, and use it to unarchive the gorm file while
	      // handling class replacement so that standard objects understood
	      // by the gui library are converted to their Gorm internal equivalents.
	      //
	      GSXibKeyedUnarchiver *u = [[GSXibKeyedUnarchiver alloc] initForReadingWithData: data];
	  
	      [u setDelegate: self];
	      
	      //
	      // Special internal classes
	      // 
	      [u setClass: [GormObjectProxy class]
		 forClassName: @"NSCustomObject"];
	      [u setClass: [GormCustomView class] 
		 forClassName: @"NSCustomView"];
	      [u setClass: [GormNSWindow class] 
		 forClassName: @"NSWindow"];
	      
	      //
	      // Substitute any classes specified by the palettes...
	      //
	      en = [substituteClasses keyEnumerator];
	      while((subClassName = [en nextObject]) != nil)
		{
		  NSString *realClassName = [substituteClasses objectForKey: subClassName];
		  Class substituteClass = NSClassFromString(subClassName);
		  [u setClass: substituteClass
		     forClassName: realClassName];
		}
	      
	      //
	      // decode
	      //
	      container = [u decodeObjectForKey: @"IBDocument.Objects"];
	      if (container == nil || [container isKindOfClass: [IBObjectContainer class]] == NO)
		{
		  result = NO;
		}
	      else
		{
		  IBObjectRecord *or = nil;
		  en = [container objectRecordEnumerator];
		  nibFilesOwner = [u objectForKey: @"File's Owner"];
		  docFilesOwner = [document filesOwner];

		  if([nibFilesOwner isKindOfClass: [GormObjectProxy class]])
		    {
		      [docFilesOwner setClassName: [nibFilesOwner className]];	  
		    }
		  
		  //
		  // add objects...
		  //
		  while((or = [en nextObject]) != nil)
		    {
		      id obj = [or object];
		      id parent = [or parent];
		      NSString *customClassName = nil;
		      NSString *objName = nil;
		      
		      // skip the file's owner, it is handled above...
		      if(obj == nibFilesOwner)
			continue;
		      
		      //
		      // if it's a window template, then replace it with an actual window.
		      //
		      if([obj isKindOfClass: [NSWindowTemplate class]])
			{
			  NSString *className = [obj className];
			  BOOL isDeferred = [obj isDeferred];
			  BOOL isVisible = YES; // [[container visibleWindows] containsObject: obj];
			  
			  // make the object deferred/visible...
			  id o = [obj nibInstantiate];
			  
			  [document setObject: o isDeferred: isDeferred];
			  [document setObject: o isVisibleAtLaunch: isVisible];

			  // record the custom class...
			  if([classManager isCustomClass: className])
			    {
			      customClassName = className;
			    }
			}
		      
		      [document attachObject: obj toParent: parent];
		      
		      if(customClassName != nil)
			{
			  objName = [document nameForObject: obj];
			  [classManager setCustomClass: customClassName forName: objName];
			}
		    }
		  
		  //
		  // Add custom classes...
		  //
		  // classesTable = [container classes];
		  // classKeys = NSAllMapTableKeys(classesTable);
		  // en = [classKeys objectEnumerator];
		  /*
		  while((o = [en nextObject]) != nil)
		    {
		      NSString *name = [document nameForObject: o];
		      NSString *customClass = NSMapGet(classesTable, o);
		      if(name != nil && customClass != nil)
			{
			  [classManager setCustomClass: customClass forName: name];
			}
		      else
			{
			  NSLog(@"Name %@ or class %@ for object %@ is nil.", name, customClass, o);
			}
		     }
		  */
		  
		  //
		  // add connections...
		  //
		  en = [container connectionRecordEnumerator];
		  IBConnectionRecord *cr = nil;
		  while((cr = [en nextObject]) != nil)
		    {
		      IBConnection *conn = [cr connection];
		      NSNibConnector *o = [conn nibConnector];
		      id dest = [o destination];
		      id src = [o source];
		      
		      if(dest == nibFilesOwner)
			{
			  [o setDestination: [document filesOwner]];
			}
		      else if(dest == nil)
			{
			  [o setDestination: [document firstResponder]];
			}
		      
		      if(src == nibFilesOwner)
			{
			  [o setSource: [document filesOwner]];
			}
		      else if(src == nil)
			{
			  [o setSource: [document firstResponder]];
			}
		      
		      // check src/dest for window template...
		      if([src isKindOfClass: [NSWindowTemplate class]])
			{
			  id win = [src realObject];
			  [o setSource: win];
			}
		      
		      if([dest isKindOfClass: [NSWindowTemplate class]])
			{
			  id win = [dest realObject];
			  [o setDestination: win];
			}
		      
		      // skip any help connectors...
		      if([o isKindOfClass: [NSIBHelpConnector class]])
			{
			  continue;
			}
		      [document addConnector: o];
		    }
		  
		  // turn on custom classes.
		  [NSClassSwapper setIsInInterfaceBuilder: NO]; 
		  
		  // clear the changes, since we just loaded the document.
		  [document updateChangeCount: NSChangeCleared];
		  
		  result = YES;
		}
	    }
	  [NSClassSwapper setIsInInterfaceBuilder: NO];      
	}
    }
  NS_HANDLER
    {
      NSRunAlertPanel(_(@"Problem Loading"), 
		      [NSString stringWithFormat: @"Failed to load file.  Exception: %@",[localException reason]], 
		      _(@"OK"), nil, nil);
      result = NO; 
    }
  NS_ENDHANDLER;

  // return the result.
  return result;
}

- (void) unarchiver: (NSKeyedUnarchiver *)unarchiver 
  willReplaceObject: (id)obj 
	 withObject: (id)newObj
{
  // Nothing for now...
}

- (id) unarchiver: (NSKeyedUnarchiver *)unarchiver didDecodeObject: (id)obj
{
  if([obj isKindOfClass: [NSWindowTemplate class]])
    {
      GormClassManager *classManager = [document classManager];
      Class clz ;
      NSString *className = [obj className];
      
      if([classManager isCustomClass: className])
	{
	  className = [classManager nonCustomSuperClassOf: className];
	}
      clz = [unarchiver classForClassName: className];
      // [obj setBaseWindowClass: clz];
    }
  else if([obj respondsToSelector: @selector(setTarget:)] &&
	  [obj respondsToSelector: @selector(setAction:)] &&
	  [obj isKindOfClass: [NSCell class]] == NO)
    {
      // blank the target/action for all objects.
      [obj setTarget: nil];
      [obj setAction: NULL];
    }

  return obj;
}
@end
