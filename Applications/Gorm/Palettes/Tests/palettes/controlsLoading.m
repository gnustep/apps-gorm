/* Copyright (C) 2026 Free Software Foundation, Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSBundle *bundle = [NSBundle bundleWithPath: @"../../2Controls/2Controls.palette"];
  Class paletteClass;

  START_SET("Controls palette loads independently")
  PASS([IBPalette class] != Nil, "InterfaceBuilder is available")
  paletteClass = [bundle classNamed: @"ControlsPalette"];
  PASS(paletteClass != Nil, "controls palette loads without another palette")
  PASS([paletteClass isSubclassOfClass: [IBPalette class]],
    "controls palette is an IBPalette")
  END_SET("Controls palette loads independently")
  RELEASE(pool);
  return 0;
}
