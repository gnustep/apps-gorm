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

@implementation GormNSWindow
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
  return [super initWithContentRect: contentRect
		styleMask: NSTitledWindowMask | NSClosableWindowMask
		| NSResizableWindowMask | NSMiniaturizableWindowMask
		backing: bufferingType
		defer: flag
		screen: aScreen];
}

- (void) setStyleMask: (unsigned)newStyleMask
{
  _gormStyleMask = newStyleMask;
}

- (unsigned) styleMask
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
*/
@end
