/* GormFunctions.m
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2004
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

#include "GormFunctions.h"
#include <AppKit/AppKit.h>

// find all subitems for the given items...
void findAllWithArray(id item, NSMutableArray *array)
{
  [array addObject: item];
  if([item isKindOfClass: [NSMenuItem class]])
    {
      if([item hasSubmenu])
	{
	  NSMenu *submenu = [item submenu];
	  NSArray *items = [submenu itemArray];
	  NSEnumerator *e = [items objectEnumerator];
	  id i = nil;

	  [array addObject: submenu];
	  while((i = [e nextObject]) != nil)
	    {
	      findAllWithArray(i, array);
	    }
	}
    } 
}

// find all sub items for the selections...
NSArray* findAllSubmenus(NSArray *array)
{
  NSEnumerator *e = [array objectEnumerator];
  id i = nil;
  NSMutableArray *results = [[NSMutableArray alloc] init];

  while((i = [e nextObject]) != nil)
    {
      findAllWithArray(i, results);
    }

  return results;
}

NSArray* findAll(NSMenu *menu)
{
  NSArray *items = [menu itemArray];
  return findAllSubmenus(items);
}
