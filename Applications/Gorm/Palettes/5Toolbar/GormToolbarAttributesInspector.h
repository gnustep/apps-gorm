/* Definition of class GormToolbarAttributesInspector
   Copyright (C) 2025 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: 13-11-2025

   This file is part of GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _GormToolbarAttributesInspector_h_INCLUDE
#define _GormToolbarAttributesInspector_h_INCLUDE

#import <InterfaceBuilder/IBInspector.h>
#import <AppKit/NSTableView.h>

#import <GNUstepBase/GSVersionMacros.h>

#if	defined(__cplusplus)
extern "C" {
#endif

GS_EXPORT_CLASS
@interface GormToolbarAttributesInspector : IBInspector <NSTableViewDelegate, NSTableViewDataSource>
{
  IBOutlet id _allowedItems;
  IBOutlet id _allowsCustomization;
  IBOutlet id _autosaves;
  IBOutlet id _defaultItems;
  IBOutlet id _displayMode;
  IBOutlet id _showsBaselineSeparator;
  IBOutlet id _sizeMode;
  IBOutlet id _visible;
  IBOutlet id _identifier;
}

- (IBAction) addAllowedItem: (id)sender;
- (IBAction) removeAllowedItem: (id)sender;

- (IBAction) addDefaultItem: (id)sender;
- (IBAction) removeDefaultItem: (id)sender;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* _GormToolbarAttributesInspector_h_INCLUDE */
