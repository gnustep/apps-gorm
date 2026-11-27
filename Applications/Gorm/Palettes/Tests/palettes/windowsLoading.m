/* Copyright (C) 2026 Free Software Foundation, Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSBundle *bundle = [NSBundle bundleWithPath: @"../../1Windows/1Windows.palette"];
  Class paletteClass;

  START_SET("Windows palette loads independently")
  PASS([IBPalette class] != Nil, "InterfaceBuilder is available")
  paletteClass = [bundle classNamed: @"WindowsPalette"];
  PASS(paletteClass != Nil, "windows palette loads without another palette")
  PASS([paletteClass isSubclassOfClass: [IBPalette class]],
    "windows palette is an IBPalette")
  END_SET("Windows palette loads independently")
  RELEASE(pool);
  return 0;
}
