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
#include <GormCore/GormWindowTemplate.h>

#include "GormXibWrapperLoader.h"

/*
 * Forward declarations for classes
 */
@class GormNSWindow;

/*
 * Xib loader...
 */
@implementation GormXibWrapperLoader
+ (NSString *) fileType
{
  return @"GSXibFileType";
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
	  [NSClassSwapper setIsInInterfaceBuilder: YES];	  
	  
	  // check the data...
	  if (data == nil) 
	    {
	      result = NO;
	    }
	  else
	    {
              NSEnumerator *en;
              GSXibKeyedUnarchiver *u;
	      //
	      // Create an unarchiver, and use it to unarchive the gorm file while
	      // handling class replacement so that standard objects understood
	      // by the gui library are converted to their Gorm internal equivalents.
	      //
	      u = [[GSXibKeyedUnarchiver alloc] initForReadingWithData: data];
	      [u setDelegate: self];
	      
	      //
	      // Special internal classes
	      // 
	      [u setClass: [GormObjectProxy class]
		 forClassName: @"NSCustomObject"];
	      [u setClass: [GormCustomView class] 
		 forClassName: @"NSCustomView"];
	      [u setClass: [GormWindowTemplate class] 
		 forClassName: @"NSWindowTemplate"];
	      [u setClass: [GormNSWindow class] 
		 forClassName: @"NSWindow"];
	      
	      //
	      // Substitute any classes specified by the palettes...
	      //
	      en = [substituteClasses keyEnumerator];
	      while ((subClassName = [en nextObject]) != nil)
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
		  IBConnectionRecord *cr = nil;
                  NSArray *rootObjects;
                  id firstResponder;

                  rootObjects = [u decodeObjectForKey: @"IBDocument.RootObjects"];
		  nibFilesOwner = [rootObjects objectAtIndex: 0];
		  firstResponder = [rootObjects objectAtIndex: 1];
		  docFilesOwner = [document filesOwner];

		  //
		  // set the current class on the File's owner...
		  //
		  if ([nibFilesOwner isKindOfClass: [GormObjectProxy class]])
		    {
		      [docFilesOwner setClassName: [nibFilesOwner className]];	  
		    }
		  
		  //
		  // add objects...
		  //
		  en = [container objectRecordEnumerator];
		  while ((or = [en nextObject]) != nil)
		    {
		      id obj = [or object];
                      id o = obj;
		      NSString *customClassName = nil;
		      NSString *objName = nil;
		      
		      // skip the file's owner, it is handled above...
		      if ((obj == nibFilesOwner) || (obj == firstResponder))
			continue;
		      
		      //
		      // if it's a window template, then replace it with an actual window.
		      //
		      if ([obj isKindOfClass: [NSWindowTemplate class]])
			{
			  NSString *className = [obj className];
			  BOOL isDeferred = [obj isDeferred];
			  BOOL isVisible = YES; // [[container visibleWindows] containsObject: obj];
			  
			  // make the object deferred/visible...
			  o = [obj nibInstantiate];

			  [document setObject: o isDeferred: isDeferred];
			  [document setObject: o isVisibleAtLaunch: isVisible];

			  // record the custom class...
			  if ([classManager isCustomClass: className])
			    {
			      customClassName = className;
			    }
			}
		      
		      if ([rootObjects containsObject: obj])
			{		  
                          id parent = [or parent];

                          [document attachObject: o toParent: parent];
                        }

		      if (customClassName != nil)
			{
			  objName = [document nameForObject: obj];
			  [classManager setCustomClass: customClassName forName: objName];
			}
		    }
		  
		  /* FIXME: Should use IBDocument.Classes
		  //
		  // Add custom classes...
		  //
		  classesTable = [container classes];
		  classKeys = NSAllMapTableKeys(classesTable);
		  en = [classKeys objectEnumerator];
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
		  while ((cr = [en nextObject]) != nil)
		    {
		      IBConnection *conn = [cr connection];
		      NSNibConnector *o = [conn nibConnector];
		      id dest = [o destination];
		      id src = [o source];
		      
		      if (dest == nibFilesOwner)
			{
			  [o setDestination: [document filesOwner]];
			}
		      else if (dest == firstResponder)
			{
			  [o setDestination: [document firstResponder]];
			}
		      
		      if (src == nibFilesOwner)
			{
			  [o setSource: [document filesOwner]];
			}
		      else if (src == firstResponder)
			{
			  [o setSource: [document firstResponder]];
			}
		      
		      // check src/dest for window template...
		      if ([src isKindOfClass: [NSWindowTemplate class]])
			{
			  id win = [src realObject];
			  [o setSource: win];
			}
		      
		      if ([dest isKindOfClass: [NSWindowTemplate class]])
			{
			  id win = [dest realObject];
			  [o setDestination: win];
			}
		      
		      // skip any help connectors...
		      if ([o isKindOfClass: [NSIBHelpConnector class]])
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
  if ([obj isKindOfClass: [NSWindowTemplate class]])
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
  else if ([obj respondsToSelector: @selector(setTarget:)] &&
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
