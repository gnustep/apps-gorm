/* GormFunctions.h
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

#ifndef	INCLUDED_GormFunctions_h
#define	INCLUDED_GormFunctions_h

#include <AppKit/AppKit.h>

// find all subitems for the given items...
void findAllWithArray(id item, NSMutableArray *array);

// find all sub items for the selections...
NSArray* findAllSubmenus(NSArray *array);

// find all items in the menu...
NSArray* findAll(NSMenu *menu);

// cut the file label to the appropriate length...
NSString *cutFileLabelText(NSString *filename, id label, int length);

// get the cell size for all editors
NSSize defaultCellSize();

#endif
