/* GModelDecoder
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author: Adam Fedor <fedor@gnu.org>
 * Date:   2002
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
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <AppKit/GMArchiver.h>
#include <AppKit/IMLoading.h>
#include <AppKit/IMCustomObject.h>
#include <AppKit/NSWindow.h>
#include <AppKit/GSDisplayServer.h>
#include "GormPrivate.h"
#include "GormCustomView.h"

static Class gmodel_class(NSString *className);

static id gormNibOwner;
static id gormRealObject;
static BOOL gormFileOwnerDecoded;

@interface GModelApplication : NSObject
{
  id mainMenu;
  id windowMenu;
  id delegate;
  NSArray *windows;
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver;
- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver;

- mainMenu;
- windowMenu;
- delegate;
- (NSArray *) windows;

@end

@interface NSWindow (GormPrivate)
- (void) gmSetStyleMask: (unsigned int)mask;
@end

@implementation NSWindow (GormPrivate)
// private method to change the Window style mask on the fly
- (void) gmSetStyleMask: (unsigned int)mask
{
   _styleMask = mask;
   [GSServerForWindow(self) stylewindow: mask : [self windowNumber]];
}
@end

@implementation GModelApplication

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSEnumerator *enumerator;
  NSWindow *win;

  mainMenu = [unarchiver decodeObjectWithName:@"mainMenu"];

  windows = [unarchiver decodeObjectWithName:@"windows"];
  enumerator = [windows objectEnumerator];
  while ((win = [enumerator nextObject]) != nil)
    {
      /* If we did not retain the windows here, they would all get 
	 released at the end of the event loop. */
      //RETAIN (win);
      /* Fix up window frames */
      NSLog(@"Updating window class %@", win);
      if ([win styleMask] == NSBorderlessWindowMask)
	{
	  [win gmSetStyleMask: NSTitledWindowMask];
	}
    }

  delegate = [unarchiver decodeObjectWithName:@"delegate"];

  return self;
}

- (NSArray *) windows
{
  return windows;
}

- mainMenu
{
  return mainMenu;
}

- windowMenu
{
  return windowMenu;
}

- delegate
{
  return delegate;
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return AUTORELEASE([[GModelApplication alloc] init]);
}

@end

@implementation GormObjectProxy (GModel)

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return AUTORELEASE([[self alloc] init]);
}

- (id)initWithModelUnarchiver: (GMUnarchiver*)unarchiver
{
  id extension;
  id realObject;
  id label;

  theClass = [unarchiver decodeStringWithName: @"className"];
  extension = [unarchiver decodeObjectWithName: @"extension"];
  realObject = [unarchiver decodeObjectWithName: @"realObject"];

  //real = [unarchiver representationForName: @"realObject" isLabeled: &label];

  if (!gormFileOwnerDecoded) 
    {
      gormFileOwnerDecoded = YES;
      gormNibOwner = self;
      gormRealObject = realObject;
    }  
  return self;
}

@end


@implementation GormCustomView (GModel)

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return AUTORELEASE([[self alloc] initWithFrame: NSMakeRect(0,0,10,10)]);
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSString *className;
  id realObject;
  id extension;

  className = [unarchiver decodeStringWithName: @"className"];
  extension = [unarchiver decodeObjectWithName: @"extension"];
  realObject = [unarchiver decodeObjectWithName: @"realObject"];
  [self setFrame: [unarchiver decodeRectWithName: @"frame"]];

  if (!gormFileOwnerDecoded) 
    {
      gormFileOwnerDecoded = YES;
      gormNibOwner = self;
      gormRealObject = realObject;
   }
  
  return self;
}

@end


@implementation GormDocument (GModel)

/* importing of legacy gmodel files.*/
- (id) openGModel: (NSString *)path
{
  id       obj, con;
  id       unarchiver;
  id       decoded;
  NSEnumerator *enumerator;
  NSArray  *gmobjects;
  NSArray  *gmconnections;
  Class    u = gmodel_class(@"GMUnarchiver");
  
  NSLog (@"Loading gmodel file %@...", path);
  /* GModel classes */
  [u decodeClassName: @"NSApplication"   asClassName: @"GModelApplication"];
  [u decodeClassName: @"IMCustomView"    asClassName: @"GormCustomView"];
  [u decodeClassName: @"IMCustomObject"  asClassName: @"GormObjectProxy"];
  /* Gorm classes */
  [u decodeClassName: @"NSMenu"          asClassName: @"GormNSMenu"];
  [u decodeClassName: @"NSWindow"        asClassName: @"GormNSWindow"];
  [u decodeClassName: @"NSBrowser"       asClassName: @"GormNSBrowser"];
  [u decodeClassName: @"NSTableView"     asClassName: @"GormNSTableView"];
  [u decodeClassName: @"NSOutlineView"   asClassName: @"GormNSOutlineView"];
  [u decodeClassName: @"NSPopUpButton"   asClassName: @"GormNSPopUpButton"];
  [u decodeClassName: @"NSPopUpButtonCell" 
         asClassName: @"GormNSPopUpButtonCell"];

  unarchiver = [u unarchiverWithContentsOfFile: path];
  if (!unarchiver)
    {
      NSLog(@"Failed to load gmodel file %@!!",path);
      return nil;
    }
  
  NSLog(@"----------------- GModel testing -----------------");
  decoded = [unarchiver decodeObjectWithName:@"RootObject"];
  gmobjects = [decoded performSelector: @selector(objects)];
  gmconnections = [decoded performSelector: @selector(connections)];
  NSLog(@"Gmodel objects = %@", gmobjects);
  NSLog(@"       Nib Owner %@ class name is %@", 
	gormNibOwner, [gormNibOwner className]);

  /* FIXME: Need to addClass:... if it isn't known */yy
  if (gormNibOwner)
    [filesOwner setClassName: [gormNibOwner className]];

  enumerator = [gmconnections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      NSNibConnector *newcon;

      newcon = AUTORELEASE([[NSNibConnector alloc] init]);
      [newcon setSource: [con source]];
      [newcon setDestination: [con destination]];
      [newcon setLabel: [con label]];
      [connections addObject: newcon];
    }

  /*
   * Now we merge the objects from the gmodel into our own data
   * structures.
   */
  enumerator = [gmobjects objectEnumerator];
  while ((obj = [enumerator nextObject]))
    {
      if (obj != gormNibOwner)
	[self setName: nil forObject: obj];
    }
  if ([gormRealObject isKindOfClass: [GModelApplication class]])
    {
      enumerator = [[gormRealObject windows] objectEnumerator];
      while ((obj = [enumerator nextObject]))
	{
	  [self setName: nil forObject: obj];
	}
      if ([gormRealObject mainMenu])
	[self setName: nil forObject: [gormRealObject mainMenu]];
    }
  else
    {
      /* Here we need to addClass:... (outlets, actions).  */
      NSLog(@"Don't understand real object %@", gormRealObject);
    }
  
  [self rebuildObjToNameMapping];
  return self;
}
@end

static 
Class gmodel_class(NSString *className)
{
  static Class gmclass = Nil;

  if (gmclass == Nil)
    {
      NSBundle	*theBundle;
      NSEnumerator *benum;
      NSString	*path;

      /* Find the bundle */
      benum = [NSStandardLibraryPaths() objectEnumerator];
      while ((path = [benum nextObject]))
	{
	  path = [path stringByAppendingPathComponent: @"Bundles"];
	  path = [path stringByAppendingPathComponent: @"libgmodel.bundle"];
	  if ([[NSFileManager defaultManager] fileExistsAtPath: path])
	    break;
	  path = nil;
	}
      NSCAssert(path != nil, @"Unable to load gmodel bundle");
      NSDebugLog(@"Loading gmodel from %@", path);

      theBundle = [NSBundle bundleWithPath: path];
      NSCAssert(theBundle != nil, @"Can't init gmodel bundle");
      gmclass = [theBundle classNamed: className];
      NSCAssert(gmclass, @"Can't load gmodel bundle");
    }
  return gmclass;
}

