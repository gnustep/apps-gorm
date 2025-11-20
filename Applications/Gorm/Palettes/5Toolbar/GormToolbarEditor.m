/* GormToolbarEditor.m
 *
 * Implementation of the editor class for NSToolbar objects in Gorm palettes.
 *
 * Copyright (C) 2025 Free Software Foundation, Inc.
 *
 * Author: Gregory Casamento <greg.casamento@gmail.com>
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

- (void)addAllowedToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar allowedItemIdentifiers] mutableCopy];
  [items addObject: item];
  [toolbar setAllowedItemIdentifiers: items];
}

- (void)removeAllowedToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar allowedItemIdentifiers] mutableCopy];
  [items removeObject: item];
  [toolbar setAllowedItemIdentifiers: items];
}

- (void)addDefaultToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar defaultItemIdentifiers] mutableCopy];
  [items addObject: item];
  [toolbar setDefaultItemIdentifiers: items];
}

- (void)removeDefaultToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar defaultItemIdentifiers] mutableCopy];
  [items removeObject: item];
  [toolbar setDefaultItemIdentifiers: items];
}

- (void)configureToolbarItem:(NSToolbarItem *)item
{
  // Present inspector UI for item properties (label, image, action, etc.)
  // Implementation would depend on Gorm's inspector infrastructure
}

@end
