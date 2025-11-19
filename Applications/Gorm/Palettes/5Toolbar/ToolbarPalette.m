/* ToolbarPalette

   Copyright (C) 2025 Free Software Foundation, Inc.

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: Nov 2025
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

/* All rights reserved */

#import <AppKit/NSToolbarItem.h>
#import <GormCore/NSToolbarPrivate.h>

#import "ToolbarPalette.h"

@interface NSToolbar (GormPrivate)
+ (void) _removeToolbarsWithIdentifier: (NSString *)identifier;
@end

@implementation ToolbarPalette

- (void) finishInstantiate
{
  NSToolbar *tb = [[NSToolbar alloc] initWithIdentifier: @"gnustep.toolbar"];
  NSMutableArray *array = nil;

  [NSToolbar _removeToolbarsWithIdentifier: @"gnustep.toolbar"]; // uncache the toolbar...
  
  // Instantiate template toolbar...
  [tb setDisplayMode: NSToolbarDisplayModeIconAndLabel];
  [tb setSizeMode: NSToolbarSizeModeDefault];
  [tb setAllowsUserCustomization: YES];
  [tb setAutosavesConfiguration: YES];
  [tb setDelegate: nil];

  // Set allowed identifiers...
  array = [[NSMutableArray alloc]
			initWithObjects:
	      NSToolbarSpaceItemIdentifier,
	    NSToolbarFlexibleSpaceItemIdentifier,
	    NSToolbarSeparatorItemIdentifier,
	    NSToolbarShowColorsItemIdentifier,
	    NSToolbarShowFontsItemIdentifier,
	    NSToolbarCustomizeToolbarItemIdentifier,
	    NSToolbarPrintItemIdentifier, nil];
  [tb setAllowedItemIdentifiers: array];

  // Set default identifiers...
  array = [[NSMutableArray alloc]
			initWithObjects:
	      NSToolbarSpaceItemIdentifier,
	    NSToolbarFlexibleSpaceItemIdentifier,
	    NSToolbarSeparatorItemIdentifier,
	    NSToolbarShowColorsItemIdentifier,
	    NSToolbarShowFontsItemIdentifier,
	    NSToolbarCustomizeToolbarItemIdentifier,
	    NSToolbarPrintItemIdentifier, nil];
  [tb setDefaultItemIdentifiers: array];

  // Associate the button
  [self associateObject: tb
		   type: IBViewPboardType
		   with: toolbarButton];
}

@end
