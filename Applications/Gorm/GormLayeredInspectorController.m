/* GormLayeredInspectorController.h
 *
 * Copyright (C) 2025 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2025
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
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

#import <AppKit/NSTableView.h>
#import "GormLayeredInspectorController.h"

@implementation GormLayeredInspectorController

// Data source

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
  return 0; // get all inspectors for the selection...
}

// Delegate

- (NSView *) tableView: (NSTableView *)tableView
    viewForTableColumn: (NSTableColumn *)tableColumn
		   row: (NSInteger)row
{
  return nil; // given the class and all subclasses, find all inspectors...
}

@end
