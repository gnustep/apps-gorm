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
#include <InterfaceBuilder/IBPalette.h>
#include "GormCustomView.h"

//  @class GormPopUpNSMenu;
@class GormNSPopUpButton;

@interface ControlsPalette: IBPalette
{
}
@end


@implementation ControlsPalette
- (void) finishInstantiate
{
  NSView	*contents;
  id		v;

  originalWindow = [[NSWindow alloc] initWithContentRect: 
				       NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [originalWindow contentView];


/*******************/
/* First Column... */
/*******************/

  // Editable text field
  v = [[NSTextField alloc] initWithFrame: NSMakeRect(10, 147, 56, 21)];
  [v setEditable: YES];
  [v setStringValue: @"Text"];
  [contents addSubview: v];
  RELEASE(v);

  // Push button
  v = [[NSButton alloc] initWithFrame: NSMakeRect(10, 110, 56, 24)];
  [v setButtonType: NSMomentaryPushButton];
  [v setTitle: @"Button"];
  [contents addSubview: v];
  RELEASE(v);

  // Checkbox
  v = [[NSButton alloc] initWithFrame: NSMakeRect(10, 80, 56, 16)];
  [v setButtonType: NSSwitchButton];
  [v setImagePosition: NSImageRight];
  [v setTitle: @"Switch"];
  [v setBordered: NO];
  [contents addSubview: v];
  RELEASE(v);

  // Radio button: default on
  v = [[NSButton alloc] initWithFrame: NSMakeRect(10, 55, 56, 16)];
  [v setButtonType: NSRadioButton];
  [v setImagePosition: NSImageLeft];
  [v setTitle: @"Radio"];
  [v setBordered: NO];
  [v setState: NSOnState];
  [contents addSubview: v];
  RELEASE(v);

  // Radio button: default off
  v = [[NSButton alloc] initWithFrame: NSMakeRect(10, 37, 56, 16)];
  [v setButtonType: NSRadioButton];
  [v setImagePosition: NSImageLeft];
  [v setTitle: @"Radio"];
  [v setBordered: NO];
  [v setState: NSOffState];
  [contents addSubview: v];
  RELEASE(v);


/********************/
/* Second Column... */
/********************/

  // Non editable text field (label)
  v = [[NSTextField alloc] initWithFrame: NSMakeRect(78, 152, 83, 18)];
  [v setEditable: NO];
  [v setSelectable: NO];
  [v setBezeled: NO];
  [v setAlignment: NSCenterTextAlignment];
  [v setFont: [NSFont systemFontOfSize: 14.0]];
  [v setDrawsBackground: NO];
  [v setStringValue: @"Title"];
  [contents addSubview: v];
  RELEASE(v);

  // Group box
  v = [[NSBox alloc] initWithFrame: NSMakeRect(78, 98, 53, 44)];
  [v setTitle: @"Box"];
  [contents addSubview: v];
  RELEASE(v);

  // Color well
  v = [[NSColorWell alloc] initWithFrame: NSMakeRect(78, 62, 53, 30)];
  [contents addSubview: v];
  RELEASE(v);

  // Horizontal Slider
  v = [[NSSlider alloc] initWithFrame: NSMakeRect(78, 39, 83, 16)];
  [v setDoubleValue: 0];
  [v setContinuous: YES];
  [contents addSubview: v];
  RELEASE(v);

  // Vertical Slider
  v = [[NSSlider alloc] initWithFrame: NSMakeRect(145, 62, 16, 76)];
  [v setDoubleValue: 0];
  [v setContinuous: YES];
  [contents addSubview: v];
  RELEASE(v);

  // Progress Indicator
  v = [[NSProgressIndicator alloc] initWithFrame: NSMakeRect(78, 15, 83, 18)];
  [v setIndeterminate: NO];
  [v setDoubleValue: 50.];
  [contents addSubview: v];
  RELEASE(v);


/*******************/
/* Third Column... */
/*******************/

  // Popup button
  v = [[GormNSPopUpButton alloc] initWithFrame: NSMakeRect(172, 147, 89, 20)];
  [v addItemWithTitle: @"Item 1"];
  [v addItemWithTitle: @"Item 2"];
  [v addItemWithTitle: @"Item 3"];
  [contents addSubview: v];
  RELEASE(v);

  // Form
  v = [[NSForm alloc] initWithFrame: NSMakeRect(172, 101, 87, 45)];
  [v addEntry: @"Field 1"];
  [v addEntry: @"Field 2"];
  [v setEntryWidth: 87];
  [v setInterlineSpacing: 3];
  [v setCellSize: NSMakeSize([v cellSize].width, 21)];
  [contents addSubview: v];
  RELEASE(v);

  // Stepper
  v = [[NSStepper alloc] initWithFrame: NSMakeRect(172, 76, 16, 23)];
  [contents addSubview: v];
  RELEASE(v);

  // CustomView
  v = [[GormCustomView alloc] initWithFrame: NSMakeRect(172, 19, 89, 40)];
  [contents addSubview: v];
  RELEASE(v);
}
@end
