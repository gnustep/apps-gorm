/** 
   main.m

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2004
   
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

#include <InterfaceBuilder/IBPalette.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSPopUpButton.h>

@class GormNSPopUpButton;

@interface ControlsPalette: IBPalette
@end


@implementation ControlsPalette
- (void) finishInstantiate
{
  NSView	*contents;
  id		v;

  contents = [originalWindow contentView];
  v = [[GormNSPopUpButton alloc] initWithFrame: NSMakeRect(118, 139, 87, 22)];
  [v addItemWithTitle: @"Item 1"];
  [v addItemWithTitle: @"Item 2"];
  [v addItemWithTitle: @"Item 3"];
  [contents addSubview: v];
  RELEASE(v);
}
@end
