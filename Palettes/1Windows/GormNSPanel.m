/* GormNSPanel.m

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2003
   Adapted from GormNSWindow.m
   
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

#include <AppKit/AppKit.h>
#include "GormNSPanel.h"


@implementation GormNSPanel
- (void)encodeWithCoder: (NSCoder*) aCoder
{
  unsigned oldStyleMask;
  oldStyleMask = _styleMask;
  _styleMask = _gormStyleMask;
  [super encodeWithCoder: aCoder];
  _styleMask = oldStyleMask;
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
		backing: bufferingType
		defer: flag
		screen: aScreen];
}

- (void)setStyleMask: (unsigned) newStyleMask
{
  _gormStyleMask = newStyleMask;
}

- (unsigned)styleMask
{
  return _gormStyleMask;
}
@end
