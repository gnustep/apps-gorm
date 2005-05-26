/* NSView+GormExtensions.m
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2004
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include "NSView+GormExtensions.h"

@implementation NSView (GormExtensions)
- (NSArray *) superviews
{
  NSMutableArray *result = [NSMutableArray array];
  NSView *currentView = nil; 
 
  for(currentView = self; currentView != nil; 
      currentView = [currentView superview])
    {
      [result addObject: currentView];
    }

  return result;
}

- (BOOL) hasSuperviewKindOfClass: (Class)cls
{
  NSEnumerator *en = [[self superviews] objectEnumerator];
  NSView *v = nil;
  BOOL result = NO;

  while(((v = [en nextObject]) != nil) && 
	result == NO)
    {
      result = [v isKindOfClass: cls];
    }

  return result;
}
@end
