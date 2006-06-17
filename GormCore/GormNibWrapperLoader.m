/* GormNibWrapperLoader
 *
 * This class is a subclass of the NSDocumentController
 *
 * Copyright (C) 2006 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2006
 *
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
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

#include <GormCore/GormWrapperLoader.h>
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
#include <GNUstepGUI/GSNibCompatibility.h>

@interface NSWindowTemplate (Private)
- (void) setBaseWindowClass: (Class) clz;
@end 

@implementation NSWindowTemplate (Private)
- (void) setBaseWindowClass: (Class) clz
{
  _baseWindowClass = clz;
}
@end

@interface GormNibWrapperLoader : GormWrapperLoader
{
  NSIBObjectData *container;
  NSMutableDictionary *swappedObjects;
  id nibFilesOwner;
}
@end

@implementation GormNibWrapperLoader
- (id) init
{
  if((self = [super init]) != nil)
    {
      swappedObjects = [[NSMutableDictionary alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(swappedObjects);
  [super dealloc];
}

+ (NSString *) type
{
  return @"GSNibFileType";
}

- (BOOL) _isTopLevelObject: (id)obj
{
  if([obj isKindOfClass: [NSWindow class]] ||
     [obj isKindOfClass: [GormObjectProxy class]])
    {
      return YES;
    }
  else if([obj isKindOfClass: [NSMenu class]])
    {
      if([obj supermenu] == nil)
	{
	  return YES;
	}
    }

  return NO;
}

- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *) doc
{
  NS_DURING
    {
      NSData		        *data = nil;
      NSData                    *classes = nil;
      NSKeyedUnarchiver		*u = nil;
      NSEnumerator		*enumerator = nil;
      NSString                  *key = nil;
      GormPalettesManager       *palettesManager = [(id<Gorm>)NSApp palettesManager];
      NSDictionary              *substituteClasses = [palettesManager substituteClasses];
      NSEnumerator              *en = [substituteClasses keyEnumerator];
      NSString                  *subClassName = nil;
      NSDictionary              *fileWrappers = nil;

      if ([super loadFileWrapper: wrapper withDocument: doc])
	{
	  GormClassManager *classManager = [document classManager];

	  key = nil;
	  fileWrappers = [wrapper fileWrappers];
	  
	  // turn off custom classes...
	  [NSClassSwapper setIsInInterfaceBuilder: YES];	  
	  enumerator = [fileWrappers keyEnumerator];
	  while((key = [enumerator nextObject]) != nil)
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
		      if (![classManager loadNibFormatCustomClassesWithData: classes]) 
			{
			  NSRunAlertPanel(_(@"Problem Loading"), 
					  _(@"Could not open the associated classes file.\n"
					    @"You won't be able to edit connections on custom classes"), 
					  _(@"OK"), nil, nil);
			}
		    }
		}
	    }
	  
	  // check the data...
	  if (data == nil || classes == nil)
	    {
	      return NO;
	    }
	  
	  /*
	   * Create an unarchiver, and use it to unarchive the gorm file while
	   * handling class replacement so that standard objects understood
	   * by the gui library are converted to their Gorm internal equivalents.
	   */
	  u = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
	  [u setDelegate: self];

	  /*
	   * Special internal classes
	   */ 
	  [u setClass: [GormObjectProxy class]
	     forClassName: @"NSCustomObject"];
	  [u setClass: [GormCustomView class] 
	     forClassName: @"NSCustomView"];
	  
	  /*
	   * Substitute any classes specified by the palettes...
	   */
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
	  container = [u decodeObjectForKey: @"IB.objectdata"];
	  if (container == nil || [container isKindOfClass: [NSIBObjectData class]] == NO)
	    {
	      return NO;
	    }
	  nibFilesOwner = [container objectForName: @"File's Owner"];

	  id docFilesOwner = [document filesOwner];
	  NSMapTable objects = [container objects];
	  NSArray *objs = NSAllMapTableKeys(objects);
	  NSEnumerator *en = [objs objectEnumerator];
	  id o = nil;

	  //
	  // set the current class on the File's owner...
	  //
	  if([nibFilesOwner isKindOfClass: [GormObjectProxy class]])
	    {
	      [docFilesOwner setClassName: [nibFilesOwner className]];	  
	    }

	  //
	  // Add the main menu first...
	  //
	  id menu = [container objectForName: @"MainMenu"];
	  if(menu)
	    {
	      [document attachObject: menu toParent: nil];
	    }

	  //
	  // add objects...
	  //
	  while((o = [en nextObject]) != nil)
	    {
	      id obj = o;
	      NSString *customClassName = nil;
	      NSString *objName = nil;

	      // skip the file's owner, it is handled above...
	      if(o == nibFilesOwner)
		continue;

	      //
	      // if it's a window template, then replace it with an actual window.
	      //
	      if([o isKindOfClass: [NSWindowTemplate class]])
		{
		  NSString *className = [o className];
		  BOOL isDeferred = [o isDeferred];
		  BOOL isVisible = [[container visibleWindows] containsObject: o];

		  // make the object deferred/visible...
		  obj = [o nibInstantiate];
		  [obj setFrame: [NSWindow frameRectForContentRect: [o windowRect] styleMask: [o windowStyle]]
		       display: NO];
		  
		  [document setObject: obj isDeferred: isDeferred];
		  [document setObject: obj isVisibleAtLaunch: isVisible];
		  // record the custom class...
		  if([classManager isCustomClass: className])
		    {
		      customClassName = className;
		    }
		}

	      if([self _isTopLevelObject: obj])
		{		  
		  [document attachObject: obj toParent: nil];
		}
	      
	      if(customClassName != nil)
		{
		  objName = [document nameForObject: obj];
		  [classManager setCustomClass: customClassName forName: objName];
		}
	    }

	  //
	  // add the swapped objects...
	  //
	  en = [swappedObjects keyEnumerator];
	  NSString *key = nil;
	  while((key = [en nextObject]) != nil)
	    {
	      NSArray *array = [swappedObjects objectForKey: key];
	      NSEnumerator *oen = [array objectEnumerator];
	      id actualObj = nil;

	      while((actualObj = [oen nextObject]) != nil)
		{
		  NSString *name = [document nameForObject: actualObj];
		  [classManager setCustomClass: key forName: name];		  
		}	      
	    }

	  //
	  // add connections...
	  //
	  en = [[container connections] objectEnumerator];
	  o = nil;
	  while((o = [en nextObject]) != nil)
	    {
	      id dest = [o destination];
	      if([o isKindOfClass: [NSNibControlConnector class]])
		{
		  NSString *tag = [o label];
		  if(dest == nibFilesOwner)
		    {
		      [o setDestination: [document filesOwner]];
		    }
		  else if(dest == nil)
		    {
		      [o setDestination: [document firstResponder]];
		    }

		  // Correct the missing colon problem...
		  NSRange colonRange = [tag rangeOfString: @":"];
		  unsigned int location = colonRange.location;
		  
		  if(location == NSNotFound)
		    {
		      NSString *newTag = [NSString stringWithFormat: @"%@:",tag];
		      [o setLabel: (id)newTag];
		    }
		}
	      [document addConnector: o];
	    }

	  // turn on custom classes.
	  [NSClassSwapper setIsInInterfaceBuilder: NO]; 

	  // clear the changes, since we just loaded the document.
	  [document updateChangeCount: NSChangeCleared];

	  return YES;
	}
    }
  NS_HANDLER
    {
      NSRunAlertPanel(_(@"Problem Loading"), 
		      [NSString stringWithFormat: @"Failed to load file.  Exception: %@",[localException reason]], 
		      _(@"OK"), nil, nil);
      return NO; 
    }
  NS_ENDHANDLER;

  // if we made it here, then it was a success....
  return YES;
}

- (void) unarchiver: (NSKeyedUnarchiver *)unarchiver willReplaceObject: (id)obj withObject: (id)newObj
{
  if([obj isKindOfClass: [NSClassSwapper class]])
    {
      NSString *className = [obj className];
      NSMutableArray *objects = [swappedObjects objectForKey: className];
      if(objects == nil)
	{
	  objects = [NSMutableArray array];
	  [swappedObjects setObject: objects forKey: className];
	}
      [objects addObject: newObj];
    }
}

- (id) unarchiver: (NSKeyedUnarchiver *)unarchiver didDecodeObject: (id)obj
{
  if([obj isKindOfClass: [NSWindowTemplate class]])
    {
      GormClassManager *classManager = [document classManager];
      NSString *className = [obj className];
      if([classManager isCustomClass: className])
	{
	  className = [classManager nonCustomSuperClassOf: className];
	}
      Class clz = [unarchiver classForClassName: className];
      [obj setBaseWindowClass: clz];
    }
  else if([obj respondsToSelector: @selector(setTarget:)] &&
	  [obj respondsToSelector: @selector(setAction:)] &&
	  [obj isKindOfClass: [NSCell class]] == NO)
    {
      // blank the target/action for all objects.
      [obj setTarget: nil];
      [obj setAction: NULL];
    }
  else if([obj isKindOfClass: [NSView class]])
    {
      [self setSuperView: nil];
    }

  return obj;
}
@end
