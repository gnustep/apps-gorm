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

  if(sel_isEqual(action, @selector(loadPalette:)))
    {
      return YES;
    }
  else if (sel_isEqual(action, @selector(close:))
      || sel_isEqual(action, @selector(miniaturize:)))
    {
      if (active == nil)
	{
	  return NO;
	}
    }
  else if (sel_isEqual(action, @selector(testInterface:)))
    {
      if (active == nil)
	{
	  return NO;
	}
    }
  else if (sel_isEqual(action, @selector(copy:)))
    {
      if ([s count] == 0)
	{
	  return NO;
	}
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
	{
	  return NO;
	}
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
	{
	  return NO;
	}
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
	{
	  return NO;
	}
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


- (IBAction) stop: (id)sender
{
  if(isTesting == NO)
    {
      // [super stop: sender];
    }
  else
    {
      [self endTesting: sender];
    }
}

- (IBAction) miniaturize: (id)sender
{
  NSWindow	*window = [(GormDocument *)[self activeDocument] window];

  [window miniaturize: self];
}

/** Info Menu Actions */
- (IBAction) preferencesPanel: (id) sender
{
  if(! preferencesController)
    {
      preferencesController =  [[GormPrefController alloc] init];
    }

  [[preferencesController panel] makeKeyAndOrderFront:nil];
}

/** Document Menu Actions */
- (IBAction) close: (id)sender
{
  GormDocument  *document = (GormDocument *)[self activeDocument];
  if([document canCloseDocument])
    {
      [document close];
    }
}

- (IBAction) debug: (id) sender
{
  [[self activeDocument] performSelector: @selector(printAllEditors)];
}

- (IBAction) loadSound: (id) sender
{
  [(GormDocument *)[self activeDocument] openSound: sender];
}

- (IBAction) loadImage: (id) sender
{
  [(GormDocument *)[self activeDocument] openImage: sender];
}


/** Edit Menu Actions */

- (IBAction) copy: (id)sender
{
  if ([[selectionOwner selection] count] == 0
      || [selectionOwner respondsToSelector: @selector(copySelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner copySelection];
}


- (IBAction) cut: (id)sender
{
  if ([[selectionOwner selection] count] == 0
      || [selectionOwner respondsToSelector: @selector(copySelection)] == NO
      || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner copySelection];
  [(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

- (IBAction) paste: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(pasteInSelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner pasteInSelection];
}


- (IBAction) delete: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

- (IBAction) selectAll: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

- (IBAction) selectAllItems: (id)sender
{
  return;
}

/** Grouping */

- (IBAction) groupSelectionInSplitView: (id)sender
{
  if ([[selectionOwner selection] count] < 2
      || [selectionOwner respondsToSelector: @selector(groupSelectionInSplitView)] == NO)
    return;

  [(GormGenericEditor *)selectionOwner groupSelectionInSplitView];
}

- (IBAction) groupSelectionInBox: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInBox)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner groupSelectionInBox];
}

- (IBAction) groupSelectionInView: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInView)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner groupSelectionInView];
}

- (IBAction) groupSelectionInScrollView: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInScrollView)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner groupSelectionInScrollView];
}

- (IBAction) groupSelectionInMatrix: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInMatrix)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner groupSelectionInMatrix];
}

- (IBAction) ungroup: (id)sender
{
  // NSLog(@"ungroup: selectionOwner %@", selectionOwner);
  if ([selectionOwner respondsToSelector: @selector(ungroup)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner ungroup];
}

/** Classes actions */

- (IBAction) createSubclass: (id)sender
{
  [(GormDocument *)[self activeDocument] createSubclass: sender];
}

- (IBAction) loadClass: (id)sender
{
  // Call the current document and create the class
  // descibed by the header
  [(GormDocument *)[self activeDocument] loadClass: sender];
}

- (IBAction) createClassFiles: (id)sender
{
  [(GormDocument *)[self activeDocument] createClassFiles: sender];
}

- (IBAction) instantiateClass: (id)sender
{
   [(GormDocument *)[self activeDocument] instantiateClass: sender];
}

- (IBAction) addAttributeToClass: (id)sender
{
  [(GormDocument *)[self activeDocument] addAttributeToClass: sender];
}

- (IBAction) remove: (id)sender
{
  [(GormDocument *)[self activeDocument] remove: sender];
}

/** Palettes Actions... */

- (IBAction) inspector: (id) sender
{
  [[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
}

- (IBAction) palettes: (id) sender
{
  [[[self palettesManager] panel] makeKeyAndOrderFront: self];
}

- (IBAction) loadPalette: (id) sender
{
  [[self palettesManager] openPalette: sender];
}

// Print

- (IBAction) print: (id) sender
{
  [[NSApp keyWindow] print: sender];
}

@end
