/* GormToolbarEditor.m
 *
 * Implementation of the editor class for NSToolbar objects in Gorm palettes.
 *
 * Copyright (C) 2025 Free Software Foundation, Inc.
 *
 * Author: Your Name <your@email.com>
 *
 * This file is part of GNUstep.
 *
 * GNUstep is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNUstep is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNUstep; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import "GormToolbarEditor.h"

@implementation GormToolbarEditor

- (NSToolbar *)toolbar
{
    return toolbar;
}

- (void)setToolbar:(NSToolbar *)aToolbar
{
    toolbar = aToolbar;
}

- (void)addToolbarItem:(NSToolbarItem *)item
{
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items addObject:item];
    [toolbar setItems:items];
}

- (void)removeToolbarItem:(NSToolbarItem *)item
{
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items removeObject:item];
    [toolbar setItems:items];
}

- (void)configureToolbarItem:(NSToolbarItem *)item
{
    // Present inspector UI for item properties (label, image, action, etc.)
    // Implementation would depend on Gorm's inspector infrastructure
}

@end
