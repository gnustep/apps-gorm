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

#include <AppKit/NSWindow.h>
#include <AppKit/NSNibConnector.h>
#include <GNUstepGUI/GMArchiver.h>
#include <GNUstepGUI/IMLoading.h>
#include <GNUstepGUI/IMCustomObject.h>
#include <GNUstepGUI/GSDisplayServer.h>
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
      /* Fix up window frames */
      if ([win styleMask] == NSBorderlessWindowMask)
	{
	  NSLog(@"Fixing borderless window %@", win);
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

  theClass = RETAIN([unarchiver decodeStringWithName: @"className"]);
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
  [self setClassName: className];

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

/* Try to define a possibly custom class that's in the gmodel
   file. This is not information that is contained in the file
   itself. For instance, we don't even know what the superclass
   is, and at best, we could search the connections to see what
   outlets and actions are used.
*/
- (void) defineClass: (id)object inFile: (NSString *)path
{
  NSString *classname = [object className];
  int result;
  NSString *header;
  NSFileManager *mgr;

  if ([classManager isKnownClass: classname])
    return;
  
  /* Can we parse a header in this directory? */
  mgr = [NSFileManager defaultManager];
  path = [path stringByDeletingLastPathComponent];
  header = [path stringByAppendingPathComponent: classname];
  header = [header stringByAppendingPathExtension: @"h"];
  if ([mgr fileExistsAtPath: header])
    {
      result = 
	NSRunAlertPanel(_(@"GModel Loading"),
			_(@"Parse %@ to define unknown class %@?"),
			_(@"Yes"), _(@"No"), _(@"Choose File"),
			header, classname, nil);
    }
  else
    {
      result = 
	NSRunAlertPanel(_(@"GModel Loading"),
			_(@"Unknown class %@. Parse header file to define?"),
			_(@"Yes"), _(@"No"), nil,
			classname, nil);
      if (result == NSAlertDefaultReturn)
	result = NSAlertOtherReturn;
    }
  if (result == NSAlertOtherReturn)
    {
      NSOpenPanel *opanel = [NSOpenPanel openPanel];
      NSArray	  *fileTypes = [NSArray arrayWithObjects: @"h", @"H", nil];
      result = [opanel runModalForDirectory: path
		       file: nil
		      types: fileTypes];
      if (result == NSOKButton)
	{
	  header = [opanel filename];
	  result = NSAlertDefaultReturn;
	}
    }

  // make a guess and warn the user
  if (result != NSAlertDefaultReturn)
    {
      NSString *superClass = nil;
      BOOL added = NO;

      if(superClass == nil && 
	 [object isKindOfClass: [GormCustomView class]])
	{
	  superClass = @"NSView";
	}
      else
	{
	  superClass = @"NSObject";
	}

      added = [classManager addClassNamed: classname
			    withSuperClassNamed: superClass
			    withActions: [NSMutableArray array]
			    withOutlets: [NSMutableArray array]];

      // inform the user...
      if(added)
	{
	  NSLog(@"Added class %@ with superclass of %@.", classname, superClass);
	}
      else
	{
	  NSLog(@"Failed to add class %@ with superclass of %@.", classname, superClass);
	}
    }
  else
    {
      [classManager parseHeader: header];
    }
}

/* Replace the proxy with the real object if necessary and make sure there
   is a name for the connection object */
- (id) connectionObjectForObject: object
{
  if (object == nil)
    return nil;
  if (object == gormNibOwner)
    object = filesOwner;
  else
    [self setName: nil forObject: object];
  return object;
}


/* importing of legacy gmodel files.*/
- (id) openGModel: (NSString *)path
{
  id                obj, con;
  id                unarchiver;
  id                decoded;
  NSEnumerator     *enumerator;
  NSArray          *gmobjects;
  NSArray          *gmconnections;
  Class             u = gmodel_class(@"GMUnarchiver");

  NSLog (@"Loading gmodel file %@...", path);
  gormNibOwner = nil;
  gormRealObject = nil;
  gormFileOwnerDecoded = NO;
  /* GModel classes */
  [u decodeClassName: @"NSApplication"   asClassName: @"GModelApplication"];
  [u decodeClassName: @"IMCustomView"    asClassName: @"GormCustomView"];
  [u decodeClassName: @"IMCustomObject"  asClassName: @"GormObjectProxy"];
  /* Gorm classes */
  [u decodeClassName: @"NSMenu"          asClassName: @"GormNSMenu"];
  [u decodeClassName: @"NSWindow"        asClassName: @"GormNSWindow"];
  [u decodeClassName: @"NSPanel"         asClassName: @"GormNSPanel"];
  [u decodeClassName: @"NSBrowser"       asClassName: @"GormNSBrowser"];
  [u decodeClassName: @"NSTableView"     asClassName: @"GormNSTableView"];
  [u decodeClassName: @"NSOutlineView"   asClassName: @"GormNSOutlineView"];
  [u decodeClassName: @"NSPopUpButton"   asClassName: @"GormNSPopUpButton"];
  [u decodeClassName: @"NSPopUpButtonCell" asClassName: @"GormNSPopUpButtonCell"];
  [u decodeClassName: @"NSOutlineView"   asClassName: @"GormNSOutlineView"];

  unarchiver = RETAIN([u unarchiverWithContentsOfFile: path]);
  if (!unarchiver)
    {
      NSLog(@"Failed to load gmodel file %@!!",path);
      return nil;
    }
  
  NSLog(@"----------------- GModel testing -----------------");
  NS_DURING
    decoded = [unarchiver decodeObjectWithName:@"RootObject"];
  NS_HANDLER
    NSRunAlertPanel(_(@"GModel Loading"), [localException reason], 
		    @"Ok", nil, nil);
    return nil;
  NS_ENDHANDLER
  gmobjects = [decoded performSelector: @selector(objects)];
  gmconnections = [decoded performSelector: @selector(connections)];
  NSLog(@"Gmodel objects = %@", gmobjects);
  NSLog(@"       Nib Owner %@ class name is %@", 
	gormNibOwner, [gormNibOwner className]);

  if (gormNibOwner)
    {
      [self defineClass: gormNibOwner inFile: path];
      [filesOwner setClassName: [gormNibOwner className]];
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

      if([obj isKindOfClass: [GormObjectProxy class]])
	{
	  NSLog(@"processing... %@",[obj className]);
	  [self defineClass: obj inFile: path];
	} 
    }

  // build connections...
  enumerator = [gmconnections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      NSNibConnector *newcon;
      id source, dest;

      source = [self connectionObjectForObject: [con source]];
      dest   = [self connectionObjectForObject: [con destination]];
      NSDebugLog(@"connector = %@",con);
      if ([[con className] isEqual: @"IMOutletConnector"]) // We don't link the gmodel library at compile time...
	{
	  newcon = AUTORELEASE([[NSNibOutletConnector alloc] init]);
	  if(![classManager isOutlet: [con label] 
			    ofClass: [source className]])
	    {
	      [classManager addOutlet: [con label] 
			    forClassNamed: [source className]];
	    }
	}
      else
	{
	  newcon = AUTORELEASE([[NSNibControlConnector alloc] init]);
	  if(![classManager isAction: [con label] 
			    ofClass: [dest className]])
	    {
	      [classManager addAction: [con label] 
			    forClassNamed: [dest className]];
	    }	  
	}
      
      NSDebugLog(@"conn = %@  source = %@ dest = %@ label = %@, src name = %@ dest name = %@", newcon, source, dest, 
		 [con label], [source className], [dest className]);
      [newcon setSource: source];
      [newcon setDestination: dest];
      [newcon setLabel: [con label]];
      [connections addObject: newcon];
    }

  if ([gormRealObject isKindOfClass: [GModelApplication class]])
    {
      enumerator = [[gormRealObject windows] objectEnumerator];
      while ((obj = [enumerator nextObject]))
	{
	  if ([self nameForObject: obj] == nil)
	    [self setName: nil forObject: obj];
	}
      if ([gormRealObject mainMenu])
	{
	  [self setName: @"NSMenu" forObject: [gormRealObject mainMenu]];
	}
    }
  else
    {
      /* Here we need to addClass:... (outlets, actions).  */
      //[self defineClass: [gormRealObject className] inFile: path];
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
