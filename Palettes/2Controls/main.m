/* main.m

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
#include "../../Gorm.h"

@interface ControlsPalette: IBPalette
{
}
@end

@implementation ControlsPalette
- (void) finishInstantiate
{
  NSView	*contents;
  id		v;

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [window contentView];

  v = [[NSTextField alloc] initWithFrame: NSMakeRect(10, 160, 80, 20)];
  [v setStringValue: @"Text"];
  [contents addSubview: v];
  RELEASE(v);

  v = [[NSButton alloc] initWithFrame: NSMakeRect(10, 125, 80, 20)];
  [v setButtonType: NSToggleButton];
  [v setTitle: @"Button"];
  [contents addSubview: v];
  RELEASE(v);

#if 0
  // Need image encoding/decoding
  v = [[NSButton alloc] initWithFrame: NSMakeRect(10, 90, 80, 20)];
  [v setButtonType: NSSwitchButton];
  [v setImagePosition: NSImageRight];
  [v setTitle: @"Switch"];
  [contents addSubview: v];
  RELEASE(v);
#endif

  v = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(10, 60, 80, 20)];
  [v addItemWithTitle: @"PopUp1"];
  [v addItemWithTitle: @"PopUp2"];
  [v addItemWithTitle: @"PopUp3"];
  [contents addSubview: v];
  RELEASE(v);

  v = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(10, 30, 80, 20)];
  [v setPullsDown: YES];
  [v addItemWithTitle: @"PullDown1"];
  [v addItemWithTitle: @"PullDown2"];
  [v addItemWithTitle: @"PullDown3"];
  [contents addSubview: v];
  RELEASE(v);

  v = [[NSTextField alloc] initWithFrame: NSMakeRect(100, 160, 80, 20)];
  [v setEditable: NO];
  [v setSelectable: NO];
  [v setBezeled: NO];
  [v setAlignment: NSCenterTextAlignment];
  [v setFont: [NSFont systemFontOfSize: 14.0]];
  [v setDrawsBackground: NO];
  [v setStringValue: @"Title"];
  [contents addSubview: v];
  RELEASE(v);

  v = [[NSSlider alloc] initWithFrame: NSMakeRect(100, 60, 14, 90)];
  [v setContinuous: YES];
  [contents addSubview: v];
  RELEASE(v);

  v = [[NSSlider alloc] initWithFrame: NSMakeRect(100, 20, 90, 14)];
  [v setContinuous: YES];
  [contents addSubview: v];
  RELEASE(v);
}
@end

