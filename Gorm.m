/* Gorm.m
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

@class	InfoPanel;

@implementation Gorm

- (id<IBDocuments>) activeDocument
{
  return activeDocument;
}

- (BOOL) applicationShouldTerminate: (NSApplication*)sender
{
  NSEnumerator	*enumerator = [[self windows] objectEnumerator];
  NSWindow	*win;
  BOOL		edited = NO;

  while ((win = [enumerator nextObject]) != nil)
    {
      if ([win isDocumentEdited] == YES)
	{
	  edited = YES;
	}
    }
  if (edited == YES)
    {
      int	result;

      result = NSRunAlertPanel(NULL, @"There are edited windows",
	@"Review Unsaved", @"Cancel", @"Quit Anyway");
      if (result == NSAlertAlternateReturn)
	{
	  return NO;
	}
      else if (result != NSAlertOtherReturn)
	{
	  enumerator = [[self windows] objectEnumerator];
	  while ((win = [enumerator nextObject]) != nil)
	    {
	      if ([win isDocumentEdited] == YES)
		{
		  [win performClose: self];
		}
	    }
	}
    }
  return YES;
}

- (void) dealloc
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];
  RELEASE(infoPanel);
  RELEASE(inspectorsManager);
  RELEASE(palettesManager);
  RELEASE(documents);
  [super dealloc];
}

- (void) handleNotification: (NSNotification*)notification
{
  NSString	*name = [notification name];
  id		obj = [notification object];

  if ([name isEqual: IBSelectionChangedNotification])
    {
      selectionOwner = [notification object];
      [[self inspectorsManager] updateSelection];
    }
  else if ([name isEqual: IBWillCloseDocumentNotification])
    {
      RETAIN(obj);
      [documents removeObjectIdenticalTo: obj];
      AUTORELEASE(obj);
      if (obj == (id)activeDocument)
	{
	  activeDocument = nil;
	}
    }
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

      documents = [NSMutableArray new];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: IBSelectionChangedNotification
	       object: nil];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: IBWillCloseDocumentNotification
	       object: nil];

      /*
       * Make sure the palettes manager exists, so that the editors and
       * inspectors provided in the standard palettes are available.
       */
      [self palettesManager];
    }
  return self;
}

- (GormInspectorsManager*) inspectorsManager
{
  if (inspectorsManager == nil)
    {
      inspectorsManager = [GormInspectorsManager new];
    }
  return inspectorsManager;
}

- (id) makeNewDocument: (id) sender
{
  id	doc = [GormDocument new];

  [documents addObject: doc];
  [doc setDocumentActive: YES];
  activeDocument = doc;
  RELEASE(doc);
  return doc;
}

- (id) openDocument: (id) sender
{
  GormDocument	*doc = [GormDocument new];

  [documents addObject: doc];
  RELEASE(doc);
  if ([doc openDocument: sender] == nil)
    {
      [documents removeObjectIdenticalTo: doc];
      doc = nil;
    }
  else
    {
      [doc setDocumentActive: YES];
      activeDocument = doc;
    }
  return doc;
}

- (id) openPalette: (id) sender
{
  return [[self palettesManager] openPalette: sender];
}

- (GormPalettesManager*) palettesManager
{
  if (palettesManager == nil)
    {
      palettesManager = [GormPalettesManager new];
    }
  return palettesManager;
}

- (id) runInfoPanel: (id) sender
{
  if (infoPanel == nil)
    {
      infoPanel = [InfoPanel new];
    }
  [infoPanel orderFront: nil];
  return self;
}

- (id) runGormInspectors: (id) sender
{
  [[[self inspectorsManager] panel] orderFront: nil];
  return self;
}

- (id) runGormPalettes: (id) sender
{
  [[[self palettesManager] panel] orderFront: self];
  return self;
}

- (id) saveAsDocument: (id)sender
{
  return [(id)activeDocument saveAsDocument: sender];
}

- (id) saveDocument: (id)sender
{
  return [(id)activeDocument saveDocument: sender];
}

- (id<IBSelectionOwners>) selectionOwner
{
  return selectionOwner;
}

- (id) selectedObject
{
  return [[selectionOwner selection] lastObject];
} 
@end

int 
main(void)
{ 
  NSAutoreleasePool	*pool;
  NSMenu		*aMenu;
  NSMenu		*mainMenu;
  NSMenu		*windowsMenu;
  NSMenuItem		*menuItem;

  pool = [NSAutoreleasePool new];
  initialize_gnustep_backend ();

  /*
   * Install an instance of Gorm as the application so that the app
   * can conform to the IB protocol
   */
  NSApp = [Gorm new];

  mainMenu = [[NSMenu alloc] initWithTitle: @"Gorm"];

  /*
   * Set up info menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Info Panel..." 
		   action: @selector(runInfoPanel:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Help..." 
		   action: NULL 
	    keyEquivalent: @"?"];
  menuItem = [mainMenu addItemWithTitle: @"Info" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  /*
   * Set up document menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Open..." 
		   action: @selector(openDocument:) 
	    keyEquivalent: @"o"];
  [aMenu addItemWithTitle: @"New Application" 
		   action: @selector(makeNewDocument:)
	    keyEquivalent: @"n"];
  [aMenu addItemWithTitle: @"Save" 
		   action: @selector(saveDocument:) 
	    keyEquivalent: @"s"];
  [aMenu addItemWithTitle: @"Save As..." 
		   action: @selector(saveAsDocument:) 
	    keyEquivalent: @"S"];
  menuItem = [mainMenu addItemWithTitle: @"Document" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  /*
   * Set up tools menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Inspector..." 
		   action: @selector(runGormInspectors:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Palettes..." 
		   action: @selector(runGormPalettes:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Load Palette..." 
		   action: @selector(openPalette:) 
	    keyEquivalent: @""];
  menuItem = [mainMenu addItemWithTitle: @"Tools" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  /*
   * Set up Windows menu
   */
  windowsMenu = [NSMenu new];
  [windowsMenu addItemWithTitle: @"Arrange"
			 action: @selector(arrangeInFront:)
		  keyEquivalent: @""];
  [windowsMenu addItemWithTitle: @"Miniaturize"
			 action: @selector(performMiniaturize:)
		  keyEquivalent: @"m"];
  [windowsMenu addItemWithTitle: @"Close"
			 action: @selector(performClose:)
		  keyEquivalent: @"w"];
  menuItem = [mainMenu addItemWithTitle: @"Windows" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: windowsMenu forItem: menuItem];
  RELEASE(windowsMenu);

  [mainMenu addItemWithTitle: @"Quit" 
		      action: @selector(terminate:)
	       keyEquivalent: @"q"];	


  [NSApp setMainMenu: mainMenu];
  [NSApp setWindowsMenu: windowsMenu];
  [mainMenu display];

{
  extern BOOL NSImageDoesCaching;
  extern BOOL NSImageForceCaching;

  NSImageDoesCaching = YES;
//[NSObject enableDoubleReleaseCheck: YES];
}

  /*
   * Set Gorm up as its own delegate
   */
  [NSApp setDelegate: NSApp];

  [NSApp run];
  [pool release];
  return 0;
}

