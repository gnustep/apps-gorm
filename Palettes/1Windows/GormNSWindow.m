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
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#include <GNUstepGUI/GSNibTemplates.h>
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
      
      // remove the default icon...
      [self setMiniwindowImage: nil];

      // set the default position mask;
      autoPositionMask = GSWindowMaxXMargin | GSWindowMaxYMargin;
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

- (BOOL) canBecomeKeyWindow
{
  return YES;
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

- (unsigned int) autoPositionMask
{
  return autoPositionMask;
}

- (void) setAutoPositionMask: (unsigned int)mask
{
  autoPositionMask = mask;
}
@end
