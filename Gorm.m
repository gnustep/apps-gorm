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

NSString *IBWillBeginTestingInterfaceNotification
  = @"IBWillBeginTestingInterfaceNotification";
NSString *IBDidBeginTestingInterfaceNotification
  = @"IBDidBeginTestingInterfaceNotification";
NSString *IBWillEndTestingInterfaceNotification
  = @"IBWillEndTestingInterfaceNotification";
NSString *IBDidEndTestingInterfaceNotification
  = @"IBDidEndTestingInterfaceNotification";


NSString *GormLinkPboardType = @"GormLinkPboardType";

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

- (GormClassManager*) classManager
{
  if (classManager == nil)
    {
      classManager = [GormClassManager new];
    }
  return classManager;
}

- (id) copy: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(copySelection)] == NO)
    return nil;
  [selectionOwner copySelection];
  return self;
}

- (id) connectDestination
{
  return connectDestination;
}

- (id) connectSource
{
  return connectSource;
}

- (id) cut: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(copySelection)] == NO
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return nil;
  [selectionOwner copySelection];
  [selectionOwner deleteSelection];
  return self;
}

- (void) dealloc
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];
  RELEASE(infoPanel);
  RELEASE(inspectorsManager);
  RELEASE(palettesManager);
  RELEASE(hiddenDuringTest);
  RELEASE(documents);
  RELEASE(classManager);
  [super dealloc];
}

- (id) delete: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return nil;
  [selectionOwner deleteSelection];
  return self;
}

- (void) displayConnectionBetween: (id)source and: (id)destination
{
  NSWindow	*w;
  NSRect	r;

  if (source != connectSource)
    {
      if (connectSource != nil)
	{
	  w = [activeDocument windowAndRect: &r forObject: connectSource];
	  if (w != nil)
	    {
	      NSView	*wv = [[w contentView] superview];

	      /*
	       * Erase image from old location.
	       */
	      r.origin.x -= 1.0;
	      r.origin.y += 1.0;
	      r.size = [sourceImage size];
	      r.size.width += 2.0;
	      r.size.height += 2.0;

	      [wv lockFocus];
	      [wv displayRect: r];
	      [wv unlockFocus];
	      [w flushWindow];
	    }
	}
      connectSource = source;
    }
  if (connectSource != nil)
    {
      w = [activeDocument windowAndRect: &r forObject: connectSource];
      if (w != nil)
	{
	  NSView	*wv = [[w contentView] superview];

	  [wv lockFocus];
	  [sourceImage compositeToPoint: r.origin
			      operation: NSCompositeCopy];
	  [wv unlockFocus];
	  [w flushWindow];
	}
    }
  if (destination != connectDestination)
    {
      if (connectDestination != nil)
	{
	  w = [activeDocument windowAndRect: &r forObject: connectDestination];
	  if (w != nil)
	    {
	      NSView	*wv = [[w contentView] superview];

	      /*
	       * Erase image from old location.
	       */
	      r.origin.x -= 1.0;
	      r.origin.y += 1.0;
	      r.size = [targetImage size];
	      r.size.width += 2.0;
	      r.size.height += 2.0;

	      [wv lockFocus];
	      [wv displayRect: r];
	      [wv unlockFocus];
	      [w flushWindow];
	    }
	}
      connectDestination = destination;
    }
  if (connectDestination != nil)
    {
      w = [activeDocument windowAndRect: &r forObject: connectDestination];
      if (w != nil)
	{
	  NSView	*wv = [[w contentView] superview];

	  [wv lockFocus];
	  [targetImage compositeToPoint: r.origin
			      operation: NSCompositeCopy];
	  [wv unlockFocus];
	  [w flushWindow];
	}
    }
}

- (id) endTesting: (id)sender
{
  if (isTesting == NO)
    {
      return nil;
    }
  else
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSEnumerator		*e;
      NSWindow			*w;
      id			val;

      [nc postNotificationName: IBWillEndTestingInterfaceNotification
			object: self];

      /*
       * Make sure windows will go away when the container is destroyed.
       */
      e = [[testContainer nameTable] objectEnumerator];
      while ((val = [e nextObject]) != nil)
	{
	  if ([val isKindOfClass: [NSWindow class]] == YES)
	    {
	      [val setReleasedWhenClosed: YES];
	      [val close];
	    }
	}
      DESTROY(testContainer);

      /*
       * Restore old windows.
       */
      e = [hiddenDuringTest objectEnumerator];
      while ((w = [e nextObject]) != nil)
	{
	  [w orderFront: self];
	}
      [hiddenDuringTest removeAllObjects];

      isTesting = NO;

      if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	{
	  [(id<IBEditors>)selectionOwner makeSelectionVisible: YES];
	}
      [nc postNotificationName: IBDidEndTestingInterfaceNotification
			object: self];
      return self;
    }
}

- (void) handleNotification: (NSNotification*)notification
{
  NSString	*name = [notification name];
  id		obj = [notification object];

  if ([name isEqual: IBSelectionChangedNotification])
    {
      /*
       * If we are connecting - stop it - a change in selection must mean
       * that the connection process has ended.
       */
      if ([self isConnecting] == YES)
	{
	  [self stopConnecting];
	}
      selectionOwner = obj;
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

- (id) infoPanel: (id) sender
{
  if (infoPanel == nil)
    {
      infoPanel = [InfoPanel new];
    }
  [infoPanel orderFront: nil];
  return self;
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSBundle			*bundle = [NSBundle mainBundle];
      NSString			*path;

      path = [bundle pathForImageResource: @"GormLinkImage"];
      linkImage = [[NSImage alloc] initWithContentsOfFile: path];
      path = [bundle pathForImageResource: @"GormSourceTag"];
      sourceImage = [[NSImage alloc] initWithContentsOfFile: path];
      path = [bundle pathForImageResource: @"GormTargetTag"];
      targetImage = [[NSImage alloc] initWithContentsOfFile: path];

      documents = [NSMutableArray new];
      hiddenDuringTest = [NSMutableArray new];
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

- (id) inspector: (id) sender
{
  [[[self inspectorsManager] panel] orderFront: nil];
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

- (BOOL) isConnecting
{
  return isConnecting;
}

- (BOOL) isTestingInterface
{
  return isTesting;
}

- (NSImage*) linkImage
{
  return linkImage;
}

- (id) loadPalette: (id) sender
{
  return [[self palettesManager] openPalette: sender];
}

- (id) newApplication: (id) sender
{
  id	doc = [GormDocument new];

  [documents addObject: doc];
  [doc setDocumentActive: YES];
  activeDocument = doc;
  RELEASE(doc);
  return doc;
}

- (id) open: (id) sender
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

- (GormPalettesManager*) palettesManager
{
  if (palettesManager == nil)
    {
      palettesManager = [GormPalettesManager new];
    }
  return palettesManager;
}

- (id) palettes: (id) sender
{
  [[[self palettesManager] panel] orderFront: self];
  return self;
}

- (id) paste: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(pasteInSelection)] == NO)
    return nil;
  [selectionOwner pasteInSelection];
  return self;
}

- (id) revertToSaved: (id)sender
{
  NSLog(@"Revert to save not yet implemented");
  return nil;
}

- (id) save: (id)sender
{
  return [(id)activeDocument saveDocument: sender];
}

- (id) saveAll: (id)sender
{
  NSEnumerator	*e = [documents objectEnumerator];
  id		doc;

  while ((doc = [e nextObject]) != nil)
    {
      if ([[doc window] isDocumentEdited] == YES)
	{
	  [doc saveDocument: sender];
	}
    }
  return self;
}

- (id) saveAs: (id)sender
{
  return [(id)activeDocument saveAsDocument: sender];
}

- (id) selectAll: (id)sender
{
  /* FIXME */
  return nil;
}

- (id<IBSelectionOwners>) selectionOwner
{
  return selectionOwner;
}

- (id) selectedObject
{
  return [[selectionOwner selection] lastObject];
} 

- (id) setName: (id)sender
{
  NSPanel	*p;
  int		r;
  NSTextField	*t;
  NSArray	*s = [selectionOwner selection];
  id		o = [s objectAtIndex: 0];
  NSString	*n;

  p = NSGetAlertPanel(@"Set Name", @"Name: ", @"OK", @"Cancel", nil);
  t = [[NSTextField alloc] initWithFrame: NSMakeRect(60,46,240,20)];
  [[p contentView] addSubview: t];
  [p makeFirstResponder: t];
  [p makeKeyAndOrderFront: self];
  [t performClick: self];
  r = [(id)p runModal];
  if (r == NSAlertDefaultReturn)
    {
      n = [[t stringValue] stringByTrimmingSpaces];
      if (n != nil && [n isEqual: @""] == NO)
	{
	  [activeDocument setName: n forObject: o];
	}
    }
  [t removeFromSuperview];
  RELEASE(t);
  NSReleaseAlertPanel(p);
  return self;
}

- (void) startConnecting
{
  if (isConnecting == YES)
    {
      return;
    }
  if (connectDestination == nil || connectSource == nil)
    {
      return;
    }
  if ([activeDocument containsObject: connectDestination] == NO)
    {
      NSLog(@"Oops - connectDestination not in active document");
      return;
    }
  if ([activeDocument containsObject: connectSource] == NO)
    {
      NSLog(@"Oops - connectSource not in active document");
      return;
    }
  isConnecting = YES;
  [[self inspectorsManager] updateSelection];
}

- (void) stopConnecting
{
  [self displayConnectionBetween: nil and: nil];
  isConnecting = NO;
}

- (id) testInterface: (id)sender
{
  if (isTesting == YES)
    {
      return nil;
    }
  else
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSEnumerator		*e;
      NSWindow			*w;
      NSData			*d;

      [nc postNotificationName: IBWillBeginTestingInterfaceNotification
			object: self];

      isTesting = YES;

      [activeDocument beginArchiving];
      d = [NSArchiver archivedDataWithRootObject: activeDocument];
      [activeDocument endArchiving];

      e = [[self windows] objectEnumerator];
      while ((w = [e nextObject]) != nil)
	{
	  if ([w isVisible] == YES
	    && [w isKindOfClass: [NSMenuWindow class]] == NO)
	    {
	      [hiddenDuringTest addObject: w];
	      [w orderOut: self];
	    }
	}

      if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	{
	  [(id<IBEditors>)selectionOwner makeSelectionVisible: NO];
	}

      testContainer = [NSUnarchiver unarchiveObjectWithData: d];
      if (testContainer != nil)
	{
	  [testContainer awakeWithContext: nil];
	  RETAIN(testContainer);
	}

      [nc postNotificationName: IBDidBeginTestingInterfaceNotification
			object: self];

      return self;
    }
}

- (BOOL) validateMenuItem: (NSMenuItem*)item
{
  SEL	action = [item action];

  if (sel_eq(action, @selector(save:))
    || sel_eq(action, @selector(saveAs:))
    || sel_eq(action, @selector(saveAll:)))
    {
      if (activeDocument == nil)
	return NO;
    }

  if (sel_eq(action, @selector(revertToSaved:)))
    {
      if (activeDocument == nil)
	return NO;
    }

  if (sel_eq(action, @selector(testInterface:)))
    {
      if (activeDocument == nil)
	return NO;
    }

  if (sel_eq(action, @selector(copy:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return [selectionOwner respondsToSelector: @selector(copySelection)];
    }

  if (sel_eq(action, @selector(cut:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return ([selectionOwner respondsToSelector: @selector(copySelection)]
	&& [selectionOwner respondsToSelector: @selector(deleteSelection)]);
    }

  if (sel_eq(action, @selector(delete:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return [selectionOwner respondsToSelector: @selector(deleteSelection)];
    }

  if (sel_eq(action, @selector(paste:)))
    {
      return [selectionOwner respondsToSelector: @selector(pasteInSelection)];
    }

  if (sel_eq(action, @selector(setName:)))
    {
      NSArray	*s = [selectionOwner selection];
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
      n = [activeDocument nameForObject: o];

      if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]
	|| [n isEqual: @"NSFont"])
	{
	  return NO;
	}
    }

  return YES;
}
@end

int 
main(void)
{ 
  NSAutoreleasePool	*pool;
  NSBundle		*bundle;
  NSString		*path;
  NSMenu		*aMenu;
  NSMenu		*mainMenu;
  NSMenu		*windowsMenu;
  NSMenuItem		*menuItem;
  Gorm			*theApp;

  pool = [NSAutoreleasePool new];
  initialize_gnustep_backend ();

  /*
   * establish registration domain defaults from file.
   */
  bundle = [NSBundle mainBundle];
  path = [bundle pathForResource: @"Defaults" ofType: @"plist"];
  if (path != nil)
    {
      NSDictionary	*dict;

      dict = [NSDictionary dictionaryWithContentsOfFile: path];
      if (dict != nil)
	{
	  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];

	  [defs registerDefaults: dict];
	}
    }

  /*
   * Install an instance of Gorm as the application so that the app
   * can conform to the IB protocol
   */
  NSApp = theApp = [Gorm new];

  mainMenu = [[NSMenu alloc] initWithTitle: @"Gorm"];

  /*
   * Set up info menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Info Panel..." 
		   action: @selector(infoPanel:) 
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
		   action: @selector(open:) 
	    keyEquivalent: @"o"];
  [aMenu addItemWithTitle: @"New Application" 
		   action: @selector(newApplication:)
	    keyEquivalent: @"n"];
  [aMenu addItemWithTitle: @"Save" 
		   action: @selector(save:) 
	    keyEquivalent: @"s"];
  [aMenu addItemWithTitle: @"Save As..." 
		   action: @selector(saveAs:) 
	    keyEquivalent: @"S"];
  [aMenu addItemWithTitle: @"Save All" 
		   action: @selector(saveAll:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Revert to Saved" 
		   action: @selector(revertToSaved:) 
	    keyEquivalent: @"u"];
  [aMenu addItemWithTitle: @"Test Interface"
		   action: @selector(testInterface:) 
	    keyEquivalent: @"r"];
  menuItem = [mainMenu addItemWithTitle: @"Document" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  /*
   * Set up edit menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Cut" 
		   action: @selector(cut:) 
	    keyEquivalent: @"x"];
  [aMenu addItemWithTitle: @"Copy" 
		   action: @selector(copy:) 
	    keyEquivalent: @"c"];
  [aMenu addItemWithTitle: @"Paste" 
		   action: @selector(paste:) 
	    keyEquivalent: @"v"];
  [aMenu addItemWithTitle: @"Delete" 
		   action: @selector(delete:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Select All" 
		   action: @selector(selectAll:) 
	    keyEquivalent: @"a"];
  [aMenu addItemWithTitle: @"Set Name..." 
		   action: @selector(setName:) 
	    keyEquivalent: @""];
  menuItem = [mainMenu addItemWithTitle: @"Edit" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  /*
   * Set up tools menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Inspector..." 
		   action: @selector(inspector:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Palettes..." 
		   action: @selector(palettes:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Load Palette..." 
		   action: @selector(loadPalette:) 
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

  /*
   * Set up Services menu
   */
  aMenu = [NSMenu new];
  menuItem = [mainMenu addItemWithTitle: @"Services" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  [mainMenu addItemWithTitle: @"Hide" 
		      action: @selector(hide:)
	       keyEquivalent: @"h"];	

  [mainMenu addItemWithTitle: @"Quit" 
		      action: @selector(terminate:)
	       keyEquivalent: @"q"];	


  [NSApp setMainMenu: mainMenu];
  [NSApp setWindowsMenu: windowsMenu];
  [mainMenu display];

{
  extern BOOL NSImageDoesCaching;

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

