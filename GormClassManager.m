/* GormClassManager.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

#include "GormPrivate.h"

@interface	GormClassManager (Private)
- (NSMutableDictionary*) classInfoForClassName: (NSString*)className;
- (NSMutableDictionary*) classInfoForObject: (NSObject*)anObject;
@end

@implementation GormClassManager

- (void) addAction: (NSString*)anAction forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraActions = [info objectForKey: @"ExtraActions"];
  NSMutableArray	*allActions = [self allActionsForObject: anObject];

  if ([extraActions containsObject: anAction] == YES)
    {
      return;	/* Can't add action twice. */
    }
  if (extraActions == nil)
    {
      extraActions = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraActions forKey: @"ExtraActions"];
      RELEASE(extraActions);
    }
  [extraActions addObject: anAction];
  if ([allActions containsObject: anAction] == NO)
    {
      [[info objectForKey: @"AllActions"] addObject: anAction];
    }
}

- (void) addOutlet: (NSString*)anOutlet forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSArray		*allOutlets = [self allOutletsForObject: anObject];

  if ([allOutlets containsObject: anOutlet] == YES)
    {
      return;	/* Can't add outlet with same name. */
    }
  if (extraOutlets == nil)
    {
      extraOutlets = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraOutlets forKey: @"ExtraOutlets"];
      RELEASE(extraOutlets);
    }
  [extraOutlets addObject: anOutlet];
  [[info objectForKey: @"AllOutlets"] addObject: anOutlet];
}

- (NSArray*) allActionsForObject: (NSObject*)obj
{
  NSString	*className;
  NSArray	*actions;
  Class		theClass = [obj class];

  if (theClass == [GormFirstResponder class])
    {
      return nil;
    }

  if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }
  if (className == nil)
    {
      NSLog(@"attempt to get actions for non-existent class");
      return nil;
    }

  actions = [self allActionsForClassNamed: className];
  while (actions == nil && (theClass = class_get_super_class(theClass)) != nil
    && theClass != [NSObject class])
    {
      className = NSStringFromClass(theClass);
      actions = [self allActionsForClassNamed: className];
    }
  return actions;
}

- (NSArray*) allActionsForClassNamed: (NSString*)className
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];

  if (info != nil)
    {
      NSMutableArray	*allActions = [info objectForKey: @"AllActions"];

      if (allActions == nil)
	{
	  NSString	*superName = [info objectForKey: @"Super"];
	  NSArray	*actions = [info objectForKey: @"Actions"];
	  NSArray	*superActions;

	  if (superName == nil)
	    {
	      superActions = nil;
	    }
	  else
	    {
	      superActions = [self allActionsForClassNamed: superName];
	    }

	  if (superActions == nil)
	    {
	      if (actions == nil)
		{
		  allActions = [NSMutableArray new];
		}
	      else
		{
		  allActions = [actions mutableCopy];
		}
	    }
	  else
	    {
	      allActions = [superActions mutableCopy];
	      if (actions != nil)
		{
		  NSEnumerator	*enumerator = [actions objectEnumerator];
		  NSString	*actionName;

		  while ((actionName = [enumerator nextObject]) != nil)
		    {
		      if ([allActions containsObject: actionName] == NO)
			{
			  [allActions addObject: actionName];
			}
		    }
		  [allActions sortUsingSelector: @selector(compare:)];
		}
	    }
	  [info setObject: allActions forKey: @"AllActions"];
	  RELEASE(allActions);
	}
      return AUTORELEASE([allActions copy]);
    }
  return nil;
}

- (NSArray*) allClassNames
{
  return [[classInformation allKeys] sortedArrayUsingSelector:
    @selector(compare:)];
}

- (NSArray*) allOutletsForObject: (NSObject*)obj
{
  NSString	*className;
  NSArray	*outlets;
  Class		theClass = [obj class];

  if (theClass == [GormFirstResponder class])
    {
      return nil;
    }

  if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }

  if (className == nil)
    {
      NSLog(@"attempt to get outlets for non-existent class");
      return nil;
    }

  outlets = [self allOutletsForClassNamed: className];
  while (outlets == nil && (theClass = class_get_super_class(theClass)) != nil
    && theClass != [NSObject class])
    {
      className = NSStringFromClass(theClass);
      outlets = [self allOutletsForClassNamed: className];
    }
  return outlets;
}

- (NSArray*) allOutletsForClassNamed: (NSString*)className;
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];

  if (info != nil)
    {
      NSMutableArray	*allOutlets = [info objectForKey: @"AllOutlets"];

      if (allOutlets == nil)
	{
	  NSString	*superName = [info objectForKey: @"Super"];
	  NSArray	*outlets = [info objectForKey: @"Outlets"];
	  NSArray	*superOutlets;

	  if (superName == nil)
	    {
	      superOutlets = nil;
	    }
	  else
	    {
	      superOutlets = [self allOutletsForClassNamed: superName];
	    }

	  if (superOutlets == nil)
	    {
	      if (outlets == nil)
		{
		  allOutlets = [NSMutableArray new];
		}
	      else
		{
		  allOutlets = [outlets mutableCopy];
		}
	    }
	  else
	    {
	      allOutlets = [superOutlets mutableCopy];
	      if (outlets != nil)
		{
		  NSEnumerator	*enumerator = [outlets objectEnumerator];
		  NSString	*outletName;

		  while ((outletName = [enumerator nextObject]) != nil)
		    {
		      if ([allOutlets containsObject: outletName] == NO)
			{
			  [allOutlets addObject: outletName];
			}
		    }
		  [allOutlets sortUsingSelector: @selector(compare:)];
		}
	    }
	  [info setObject: allOutlets forKey: @"AllOutlets"];
	  RELEASE(allOutlets);
	}
      return AUTORELEASE([allOutlets copy]);
    }
  return nil;
}

- (NSMutableDictionary*) classInfoForClassName: (NSString*)className
{
  NSMutableDictionary	*info;

  info = [classInformation objectForKey: className];
  if (info == nil)
    {
      Class	theClass = NSClassFromString(className);

      if (theClass != nil)
	{
	  theClass = class_get_super_class(theClass);
	  if (theClass != nil && theClass != [NSObject class])
	    {
	      NSString			*name;
	      NSMutableDictionary	*dict;

	      name = NSStringFromClass(theClass);
	      dict = [self classInfoForClassName: name];
	      if (dict != nil)
		{
		  id	o;

		  info = [[NSMutableDictionary alloc] initWithCapacity: 3];
		  [info setObject: name forKey: @"Super"];
		  o = [[self allActionsForClassNamed: name] mutableCopy];
		  [info setObject: o forKey: @"AllActions"];
		  o = [[self allOutletsForClassNamed: name] mutableCopy];
		  [info setObject: o forKey: @"AllOutlets"];
		  [classInformation setObject: info forKey: className];
		  RELEASE(info);
		}
	    }
	}
    } 
  return info;
}

- (NSMutableDictionary*) classInfoForObject: (NSObject*)obj
{
  NSString		*className;
  Class			theClass = [obj class];

  if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }

  if (className == nil)
    {
      NSLog(@"attempt to get outlets for non-existent class");
      return nil;
    }
  return [self classInfoForClassName: className];
}

- (void) dealloc
{
  RELEASE(classInformation);
  [super dealloc];
}

- (NSArray*) extraActionsForObject: (NSObject*)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];

  return [info objectForKey: @"ExtraActions"];
}
 
- (NSArray*) extraOutletsForObject: (NSObject*)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];

  return [info objectForKey: @"ExtraOutlets"];
}
 
- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSBundle			*bundle = [NSBundle mainBundle];
      NSString			*path;
      NSDictionary		*dict;
      NSEnumerator		*enumerator;
      NSString			*key;

      path = [bundle pathForResource: @"ClassInformation" ofType: @"plist"];
      if (path == nil)
	{
	  NSLog(@"ClassInformation.plist missing from resources");
	  dict = nil;
	}
      else
	{
	  dict = [NSDictionary dictionaryWithContentsOfFile: path];
	}

      /*
       * Convert property-list data into a mutable structure.
       */
      classInformation = [NSMutableDictionary new]; 
      enumerator = [dict keyEnumerator];
      while ((key = [enumerator nextObject]) != nil)
	{
	  NSDictionary		*classInfo = [dict objectForKey: key];
	  NSMutableDictionary	*newInfo;
	  id			obj;

	  newInfo = [NSMutableDictionary new];
	  [classInformation setObject: newInfo forKey: key];
	  RELEASE(newInfo);

	  obj = [classInfo objectForKey: @"Super"];
	  if (obj != nil)
	    {
	      [newInfo setObject: obj forKey: @"Super"];
	    }
	  obj = [classInfo objectForKey: @"Outlets"];
	  if (obj != nil)
	    {
	      obj = [obj mutableCopy];
	      [obj sortUsingSelector: @selector(compare:)];
	      [newInfo setObject: obj forKey: @"Outlets"];
	      RELEASE(obj);
	    }
	  obj = [classInfo objectForKey: @"Actions"];
	  if (obj != nil)
	    {
	      obj = [obj mutableCopy];
	      [obj sortUsingSelector: @selector(compare:)];
	      [newInfo setObject: obj forKey: @"Actions"];
	      RELEASE(obj);
	    }
	}
    }
  return self;
}

- (void) removeAction: (NSString*)anAction forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraActions = [info objectForKey: @"ExtraActions"];

  if ([extraActions containsObject: anAction] == YES)
    {
      NSString	*superName = [info objectForKey: @"Super"];

      if (superName != nil)
	{
	  NSArray	*superActions;

	  /*
	   * If this action is new in this class (ie not overriding an
	   * action in a parent) then we remove it from the list of all
	   * actions that the object responds to.
	   */
	  superActions = [self allActionsForClassNamed: superName];
	  if ([superActions containsObject: anAction] == NO)
	    {
	      NSMutableArray	*array = [info objectForKey: @"AllActions"];

	      [array removeObject: anAction];
	    }
	}
      [extraActions removeObject: anAction];
    }
}

- (void) removeOutlet: (NSString*)anOutlet forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraOutlets = [info objectForKey: @"ExtraOutlets"];

  if ([extraOutlets containsObject: anOutlet] == YES)
    {
      NSMutableArray	*allOutlets = [info objectForKey: @"AllOutlets"];

      [allOutlets removeObject: anOutlet];
      [extraOutlets removeObject: anOutlet];
    }
}

@end


@interface GormClassInspector : IBInspector
{
  NSArray		*actions;
  NSArray		*outlets;
  NSBrowser		*browser;
  BOOL			editClass;
  BOOL			editActions;
}
- (void) updateButtons;
@end

@implementation GormClassInspector

- (int) browser: (NSBrowser*)sender numberOfRowsInColumn: (int)column
{
  if (column == 0)
    {
      return [outlets count];
    }
  else
    {
      return [actions count];
    }
}

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (int)col
{
  if (col == 0)
    {
    }
  [self updateButtons];
  return YES;
}

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)aCell
	   atRow: (int)row
	  column: (int)col
{
  NSString	*name;

  if (col == 0)
    {
      if (row >= 0 && row < [outlets count])
	{
	  name = [outlets objectAtIndex: row];
	  [aCell setStringValue: name];
	  [aCell setEnabled: YES];
	}
      else
	{
	  [aCell setStringValue: @""];
	  [aCell setEnabled: NO];
	}
    }
  else
    {
      if (row >= 0 && row < [actions count])
	{
	  name = [actions objectAtIndex: row];
	  [aCell setStringValue: name];
	  [aCell setEnabled: YES];
	}
      else
	{
	  [aCell setStringValue: @""];
	  [aCell setEnabled: NO];
	}
    }
  [aCell setLeaf: YES];
}

- (void) dealloc
{
  RELEASE(actions);
  RELEASE(outlets);
  RELEASE(okButton);
  RELEASE(revertButton);
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSRect		windowRect = NSMakeRect(0, 0, IVW, IVH-IVB);
      NSRect		rect;
      NSButtonCell	*cell;
      NSTextField	*text;
      NSMatrix		*matrix;

      window = [[NSWindow alloc] initWithContentRect: windowRect
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      rect = windowRect;
      rect.origin.y += rect.size.height - 22;
      rect.size.height = 22;

      text = [[NSTextField alloc] initWithFrame: rect];
      [contents addSubview: text];
      RELEASE(text);

      cell = [[NSButtonCell alloc] init];
      [cell setButtonType: NSRadioButton];
      [cell setBordered: NO];
      [cell setImagePosition: NSImageLeft]; 
  
      rect.origin.y -= 22;
      rect.size.height = 20;
      matrix = [[NSMatrix alloc] initWithFrame: rect
					  mode: NSRadioModeMatrix
				     prototype: cell
				  numberOfRows: 1
			       numberOfColumns: 2];   
      RELEASE(cell);

      rect.size.width /= 2;
      [matrix setIntercellSpacing: NSZeroSize];
      [matrix setCellSize: rect.size];
      [matrix setTarget: self];
      [matrix setAutosizesCells: YES];
  
      cell = [matrix cellAtRow: 0 column: 0];
      [cell setTitle: @"Outlets"];
      [cell setAction: @selector(setOutlets:)];	
  
      cell = [matrix cellAtRow: 0 column: 1];
      [cell setTitle: @"Actions"];
      [cell setAction: @selector(setActions:)];	
  
      [matrix selectCellAtRow: 0 column: 0];
      [matrix setAutoresizingMask: (NSViewMinYMargin | NSViewWidthSizable)];
      [contents addSubview: matrix];
      RELEASE(matrix);

      rect = windowRect;
      rect.size.height -= 70;
      rect.origin.y += 25;

      browser = [[NSBrowser alloc] initWithFrame: rect];
      [browser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [browser setMaxVisibleColumns: 2];
      [browser setAllowsMultipleSelection: NO];
      [browser setHasHorizontalScroller: NO];
      [browser setTitled: NO];
      [browser setDelegate: self];

      [contents addSubview: browser];
      RELEASE(browser);

      rect = windowRect;
      rect.size.height = 22;
      rect.origin.y = 0;
      text = [[NSTextField alloc] initWithFrame: rect];
      [contents addSubview: text];
      RELEASE(text);

      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: @"Add"];
      [okButton setEnabled: NO];

      revertButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [revertButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [revertButton setAction: @selector(revert:)];
      [revertButton setTarget: self];
      [revertButton setTitle: @"Revert"];
      [revertButton setEnabled: NO];
    }
  return self;
}

- (void) ok: (id)sender
{
}

- (id) setActions: (id)sender
{
  if (editActions == NO)
    {
      editActions = YES;
      [self updateButtons];
    }
  return self;
}

- (void) setObject: (id)anObject
{
  if (anObject != nil && anObject != object)
    {
      ASSIGN(object, anObject);
      ASSIGN(actions, [[NSApp classManager] allActionsForObject: object]);
      ASSIGN(outlets, [[NSApp classManager] allOutletsForObject: object]);

      [browser loadColumnZero];
      [browser reloadColumn: 1];
      [self updateButtons];
    }
}

- (id) setOutlets: (id)sender
{
  if (editActions == YES)
    {
      editActions = NO;
      [self updateButtons];
    }
  return self;
}

- (void) updateButtons
{
  if (editClass == YES)
    {
      [okButton setTitle: @"Rename Class"];
      [revertButton setTitle: @"Add Class"];
    }
  else if (editActions == YES)
    {
      [okButton setTitle: @"Rename Action"];
      [revertButton setTitle: @"Add Action"];
    }
  else
    {
      [okButton setTitle: @"Rename Outlet"];
      [revertButton setTitle: @"Add Outlet"];
    }
}

- (BOOL) wantsButtons
{
  return YES;
}
@end

