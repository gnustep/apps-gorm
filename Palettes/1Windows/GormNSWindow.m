/* GormWindow.m

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   
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

#include "GormNSWindow.h"

// the default style mask we start with.
static unsigned int defaultStyleMask = NSTitledWindowMask | NSClosableWindowMask
		  | NSResizableWindowMask | NSMiniaturizableWindowMask;

@implementation GormNSWindow
/*
- (void) setFrameForMask: (unsigned int)mask
{
  NSRect newFrame;

  // Reset the frame with the style...
  newFrame = [NSWindow frameRectForContentRect: contentRect styleMask: mask];
  [window setFrame: newFrame display: NO];
}
*/

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  unsigned oldStyleMask;

  // save the old values...
  oldStyleMask = _styleMask;

  // set the values we wish to save.. after save restore.
  _styleMask = _gormStyleMask;
  [self setReleasedWhenClosed: _gormReleasedWhenClosed];
  [super encodeWithCoder: aCoder];
  _styleMask = oldStyleMask;
  [self setReleasedWhenClosed: NO];
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
		    screen: (NSScreen*)aScreen
{
  _gormStyleMask = aStyle;
  // _originalContentRect = contentRect;
  self = [super initWithContentRect: contentRect
		  styleMask: defaultStyleMask
		  backing: bufferingType
		  defer: flag
		  screen: aScreen];
  if(self != nil)
    {
      // Don't release when the window is closed, a window being edited may
      // be periodically opened and closed.
      [self setReleasedWhenClosed: NO];
    }

  return self;
}

- (void) _setStyleMask: (unsigned int)newStyleMask
{
  _gormStyleMask = newStyleMask;
}

- (unsigned int) _styleMask
{
  return _gormStyleMask;
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (NSString *) className
{
  return @"NSWindow";
}

- (void) _setReleasedWhenClosed: (BOOL) flag
{
  _gormReleasedWhenClosed = flag;
}

- (BOOL) _isReleasedWhenClosed
{
  return _gormReleasedWhenClosed;
}

// for testing...
/*
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

- (void) dealloc
{
  NSLog(@"Deallocing %@",self);
  [super dealloc];
}

- (void) orderFront: (id)sender
{
  NSLog(@"Ordering front...%@",self);
  [super orderFront: sender];
}

- (void) orderFrontRegardless
{
  NSLog(@"Ordering front regardless...%@",self);
  [super orderFrontRegardless];
}

- (void) orderWindow: (NSWindowOrderingMode)place relativeTo: (int)otherWin
{
  // NSLog(@"Ordering window %@",self);
  [super orderWindow: place relativeTo: otherWin];
}

- (void) orderOut: (id)sender
{
  NSLog(@"Ordering out...%@",self);
  [super orderOut: sender];
}
*/
@end
