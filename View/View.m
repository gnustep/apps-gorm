/* View.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard frith-Macdonald (richard@brainstorm.co.uk>
   Date: 1999
   
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
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <AppKit/GSHbox.h>
#include "../Gorm.h"

@interface ViewPalette: IBPalette
{
}
@end

@implementation ViewPalette
- (void) finishInstantiate
{
  NSView	*contents;
  id		v;

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [window contentView];

  v = [[NSButton alloc] initWithFrame: NSMakeRect(35, 60, 80, 20)];
  [v setBordered: YES];
  [v setTitle: @"Button"];
  [contents addSubview: v];
  RELEASE(v);
}
@end

