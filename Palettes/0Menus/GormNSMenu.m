/* GormNSMenu.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2002
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "GormNSMenu.h"
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

@interface GormNSMenuWindow : NSPanel
@end

@implementation GormNSMenuWindow
- (BOOL)canBecomeMainWindow
{
  return YES;
}
- (BOOL)canBecomeKeyWindow
{
  return YES;
}

- (void)resignMainWindow
{
  [super resignMainWindow];
  if ([[self menu] _ownedByPopUp])
    {
      [[NSRunLoop currentRunLoop]
	performSelector: @selector(close)
	target: [self menu]
	argument: nil
	order: 500000
	modes: [NSArray arrayWithObjects: NSDefaultRunLoopMode, 
			NSModalPanelRunLoopMode,
			NSEventTrackingRunLoopMode, 
			nil]];
    }
}

- (void) sendEvent: (NSEvent*)theEvent
{
  NSEventType   type;

  type = [theEvent type];
  if (type == NSLeftMouseDown)
    {
      [self makeMainWindow];
      [self makeKeyWindow];
    }

  [super sendEvent: theEvent];
}


- (void) dealloc
{
  [self setMenu: nil];
  [super dealloc];
}
@end

@implementation GormNSMenu
- (id) initWithCoder: (NSCoder *)coder
{
  if((self = [super initWithCoder: coder]) != nil)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc addObserver: self
	  selector: @selector(handleNotification:)
	  name: IBSelectionChangedNotification
	  object: nil];
    }

  return self;
}

- (void) handleNotification: (NSNotification *)notification
{
  id<IBEditors> object = [notification object];
  if(object != nil)
    {
      // don't call, unless it does respond...
      if([(id)object respondsToSelector: @selector(editedObject)])
	{
	  id edited = [object editedObject];
	  if(self != edited && [self _ownedByPopUp])
	    {
	      if([[self window] isVisible])
		{
		  [self close];
		}
	    }
	}
      else
	{
	  // Close anyway if the editor doesn't respond.
	  if([[self window] isVisible])
	    {
	      [self close];
	    }
	}
    }
}

- (BOOL) performKeyEquivalent: (NSEvent*)theEvent
{
  return NO;
}

- (NSPanel*) _createWindow
{
  NSPanel *win = [[GormNSMenuWindow alloc] 
		   initWithContentRect: NSZeroRect
		   styleMask: NSBorderlessWindowMask
		   backing: NSBackingStoreBuffered
		   defer: YES];
 
  [win setMenu: self];
  [win setLevel: NSSubmenuWindowLevel];
  [win setExcludedFromWindowsMenu: YES];
  RETAIN(win); // FIXME: Argh..  this may leak.. temporary fix.

  return win;
}

- (NSString *)className
{
  return @"NSMenu";
}

#ifdef DEBUG
// These methods are purely for debugging purposes...
/*
- (void) display
{
  NSDebugLog(@"In GormNSMenu display...");
  [super display];
}

- (id) retain
{
  NSLog(@"Being retained... %d: %@", [self retainCount], self);
  return [super retain];
}

- (oneway void) release
{
  NSLog(@"Being released... %d: %@", [self retainCount], self);
  [super release];
}
*/
#endif

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self
					name: IBSelectionChangedNotification
					object: nil];
  [super dealloc];
}

@end

@implementation NSMenu (GormNSMenu)
+ (id) allocSubstitute
{
  return [GormNSMenu alloc];
}
@end
