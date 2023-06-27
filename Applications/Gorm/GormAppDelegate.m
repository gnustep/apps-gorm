/* GormAppDelegate.m
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

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>

#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>

#import "GormAppDelegate.h"

@implementation GormAppDelegate

// App delegate...
- (BOOL)applicationShouldOpenUntitledFile: (NSApplication *)sender
{
  if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil) ==
      NSWindows95InterfaceStyle)
    {
      return YES;
    }

  return NO;
}

- (void) applicationOpenUntitledFile: (NSApplication *)sender
{
  GormDocumentController *dc = [GormDocumentController sharedDocumentController];
  // open a new document and build an application type document by default...
  [dc newDocument: sender];
}


- (void) applicationDidFinishLaunching: (NSNotification *)n
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ( [defaults boolForKey: @"ShowInspectors"] )
    {
      [[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
    }
  if ( [defaults boolForKey: @"ShowPalettes"] )
    {
      [[[self palettesManager] panel] makeKeyAndOrderFront: self];
    }
}

- (void) applicationWillTerminate: (NSNotification *)n
{
  [[NSUserDefaults standardUserDefaults]
    setBool: [[[self inspectorsManager] panel] isVisible]
    forKey: @"ShowInspectors"];
  [[NSUserDefaults standardUserDefaults]
    setBool: [[[self palettesManager] panel] isVisible]
    forKey: @"ShowPalettes"];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
  if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil) ==
      NSWindows95InterfaceStyle)
    {
      GormDocumentController *docController;
      docController = [GormDocumentController sharedDocumentController];

      if ([[docController documents] count] > 0)
	{
	  return NO;
	}
      else
	{
	  return YES;
	}
    }

  return NO;
}


- (BOOL) validateMenuItem: (NSMenuItem*)item
{
  GormDocument	*active = (GormDocument*)[self activeDocument];
  SEL		action = [item action];
  GormClassManager *cm = nil;
  NSArray	*s = nil;

  // if we have an active document...
  if(active != nil)
    {
      cm = [active classManager];
      s = [selectionOwner selection];
    }

  if (sel_isEqual(action, @selector(close:))
      || sel_isEqual(action, @selector(miniaturize:)))
    {
      if (active == nil)
	return NO;
    }
  else if (sel_isEqual(action, @selector(testInterface:)))
    {
      if (active == nil)
	return NO;
    }
  else if (sel_isEqual(action, @selector(copy:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	    o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return [selectionOwner respondsToSelector: @selector(copySelection)];
    }
  else if (sel_isEqual(action, @selector(cut:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	    o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return ([selectionOwner respondsToSelector: @selector(copySelection)]
	&& [selectionOwner respondsToSelector: @selector(deleteSelection)]);
    }
  else if (sel_isEqual(action, @selector(delete:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	    o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return [selectionOwner respondsToSelector: @selector(deleteSelection)];
    }
  else if (sel_isEqual(action, @selector(paste:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return [selectionOwner respondsToSelector: @selector(pasteInSelection)];
    }
  else if (sel_isEqual(action, @selector(setName:)))
    {
      NSString	*n;
      id	o;

      if ([s count] == 0)
	{
	  return NO;
	}
      if ([s count] > 1)
	{
	  return NO;
	}
      o = [s objectAtIndex: 0];
      n = [active nameForObject: o];

      if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]
	|| [n isEqual: @"NSFont"] || [n isEqual: @"NSMenu"])
	{
	  return NO;
	}
      else if(![active isTopLevelObject: o])
	{
	  return NO;
	}
    }
  else if(sel_isEqual(action, @selector(createSubclass:)) ||
	  sel_isEqual(action, @selector(loadClass:)) ||
	  sel_isEqual(action, @selector(createClassFiles:)) ||
	  sel_isEqual(action, @selector(instantiateClass:)) ||
	  sel_isEqual(action, @selector(addAttributeToClass:)) ||
	  sel_isEqual(action, @selector(remove:)))
    {
      if(active == nil)
	{
	  return NO;
	}

      if(![active isEditingClasses])
	{
	  return NO;
	}

      if(sel_isEqual(action, @selector(createSubclass:)))
	{
	  NSArray *s = [selectionOwner selection];
	  id o = nil;
	  NSString *name = nil;

	  if([s count] == 0 || [s count] > 1)
	    return NO;

	  o = [s objectAtIndex: 0];
	  name = [o className];

	  if([active classIsSelected] == NO)
	    {
	      return NO;
	    }

	  if([name isEqual: @"FirstResponder"])
	    return NO;
	}

      if(sel_isEqual(action, @selector(createClassFiles:)) ||
	 sel_isEqual(action, @selector(remove:)))
	{
	  id o = nil;
	  NSString *name = nil;

	  if ([s count] == 0)
	    {
	      return NO;
	    }
	  if ([s count] > 1)
	    {
	      return NO;
	    }

	  o = [s objectAtIndex: 0];
	  name = [o className];
	  if(![cm isCustomClass: name])
	    {
	      return NO;
	    }
	}

      if(sel_isEqual(action, @selector(instantiateClass:)))
	{
	  id o = nil;
	  NSString *name = nil;

	  if ([s count] == 0)
	    {
	      return NO;
	    }
	  if ([s count] > 1)
	    {
	      return NO;
	    }

	  if([active classIsSelected] == NO)
	    {
	      return NO;
	    }

	  o = [s objectAtIndex: 0];
	  name = [o className];
	  if(name != nil)
	    {
	      id cm = [self classManager];
	      return [cm canInstantiateClassNamed: name];
	    }
	}
    }
  else if(sel_isEqual(action, @selector(loadSound:)) ||
	  sel_isEqual(action, @selector(loadImage:)) ||
	  sel_isEqual(action, @selector(debug:)))
    {
      if(active == nil)
	{
	  return NO;
	}
    }

  return YES;
}

@end
