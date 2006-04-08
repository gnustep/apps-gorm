/* GormProtocol.h
 *
 * Copyright (C) 1999, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2005
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

#ifndef INCLUDED_GormProtocol_h
#define INCLUDED_GormProtocol_h

#include <Foundation/NSObject.h>

@class GormClassManager, GormPalettesManager, GormInspectorsManager, NSString, NSMenu;

@protocol Gorm

// Connections
- (id) connectSource;
- (id) connectDestination;
- (void) displayConnectionBetween: (id)source and: (id)destination;
- (BOOL) isConnecting;
- (void) stopConnecting;

// preferences
- (void) preferencesPanel: (id) sender;

// Cut/Paste operations
- (void) copy: (id)sender;
- (void) cut: (id)sender;
- (void) paste: (id)sender;
- (void) delete: (id)sender;
- (void) selectAllItems: (id)sender;
- (void) setName: (id)sender;

// palettes/inspectors.
- (void) inspector: (id) sender;
- (void) palettes: (id) sender;
- (void) loadPalette: (id) sender;
- (GormPalettesManager*) palettesManager;
- (GormInspectorsManager*) inspectorsManager;

// file manipulation
- (void) newGormDocument: (id) sender;
- (void) open: (id)sender;
- (void) revertToSaved: (id)sender;
- (void) save: (id)sender;
- (void) saveAll: (id)sender;
- (void) saveAs: (id)sender;

// testing the interface
- (void) testInterface: (id)sender;
- (id) endTesting: (id)sender;

// sound & images
- (void) loadSound: (id) sender;
- (void) loadImage: (id) sender;

// grouping/layout
- (void) arrangeSelectedObjects: (id)sender;
- (void) alignSelectedObjects: (id)sender;
- (void) groupSelectionInSplitView: (id)sender;
- (void) groupSelectionInBox: (id)sender;
- (void) groupSelectionInScrollView: (id)sender;
- (void) ungroup: (id)sender;

// added for classes support
- (GormClassManager*) classManager;
- (void) createSubclass: (id)sender;
- (void) instantiateClass: (id)sender;
- (NSMenu*) classMenu;

// utility
- (BOOL) documentNameIsUnique: (NSString *)filename;

// language translation
- (void) translate: (id)sender;
- (void) exportStrings: (id)sender;
@end

#endif
