/* GormInspectorsManager.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003
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

#ifndef INCLUDED_GormInspectorsManager_h
#define INCLUDED_GormInspectorsManager_h

#include <Foundation/Foundation.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

@class NSPanel;
@class NSMutableDictionary;
@class NSPopUpButton;
@class NSView;
@class NSBox;
@class IBInspector;

/**
 * GormInspectorsManager coordinates the inspector panels that display and edit properties of selected objects. It maintains a cache of inspector instances, manages the inspector panel display, and handles switching between different inspector types based on the current selection.
 */
@interface GormInspectorsManager : IBInspectorManager
{
  IBOutlet NSPanel	 *panel;
  NSMutableDictionary	 *cache;
  IBOutlet NSPopUpButton *popup;
  IBOutlet NSBox	 *selectionView;
  IBOutlet NSBox         *inspectorView;
  NSView		 *buttonView;
  NSString		 *oldInspector;
  IBOutlet IBInspector	 *inspector;
  int			 current;
  BOOL			 hiddenDuringTest;
  NSRect                 origFrame;
}
/**
 * Returns the panel window that displays the current palette contents.
 */
- (NSPanel*) panel;
/**
 * Sets the inspector panel to display the class inspector, which shows class hierarchy and allows class editing.
 */
- (void) setClassInspector;
/**
 * Sets the currently active inspector to the specified inspector object, updating the panel to display that inspector's view.
 */
- (void) setCurrentInspector: (id)anObject;
/**
 * Updates the inspector panel to reflect the currently selected object or objects, switching to the appropriate inspector type if needed.
 */
- (void) updateSelection;
@end

#endif
