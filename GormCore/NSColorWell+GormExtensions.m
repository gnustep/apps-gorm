/* NSColor+GormExtensions.m
 *
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2005
 *
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <AppKit/NSView.h>
#include <AppKit/NSColorPanel.h>
#include "NSColorWell+GormExtensions.h"

@implementation NSColorWell (GormExtensions)
- (void) setColorWithoutAction: (NSColor *)color
{
  ASSIGN(_the_color, color);
  /*
   * Experimentation with NeXTstep shows that when the color of an active
   * colorwell is set, the color of the shared color panel is set too,
   * though this does not raise the color panel, only the event of
   * activation does that.
   */
  if ([self isActive])
    {
      NSColorPanel	*colorPanel = [NSColorPanel sharedColorPanel];

      [colorPanel setColor: _the_color];
    }
  [self setNeedsDisplay: YES];
}
@end
