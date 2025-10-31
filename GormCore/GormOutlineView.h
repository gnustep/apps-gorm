/* 
   GormOutlineView.h

   The outline class.
   
   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: July 2002
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef INCLUDED_GormOutlineView_h
#define INCLUDED_GormOutlineView_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@class NSTableColumn;
@class NSMenuItem;

typedef enum {None, Outlets, Actions} GSAttributeType;

/**
 * GormOutlineView displays and manages the list of actions and outlets for a selected class
 * in the inspector. It tracks the editing state and provides accessors for the columns used
 * to present actions and outlets in the outline view.
 */
@interface GormOutlineView : NSOutlineView
{
  float _attributeOffset;
  BOOL _isEditing;
  id _itemBeingEdited;
  NSTableColumn *_actionColumn;
  NSTableColumn *_outletColumn;
  GSAttributeType _edittype;
  NSMenuItem *_menuItem;
}

// Instance methods
/**
 * Returns the horizontal offset used to align attribute text.
 */
- (float)attributeOffset;
/**
 * Sets the horizontal offset used to align attribute text.
 */
- (void)setAttributeOffset: (float)offset;
/**
 * Returns the model item currently being edited.
 */
- (id) itemBeingEdited;
/**
 * Sets the model item to mark as being edited.
 */
- (void) setItemBeingEdited: (id)item;
/**
 * Returns YES if an item is currently being edited; NO otherwise.
 */
- (BOOL) isEditing;
/**
 * Sets whether an item is currently being edited.
 */
- (void) setIsEditing: (BOOL)flag;
/**
 * Returns the table column used to display actions.
 */
- (NSTableColumn *)actionColumn;
/**
 * Sets the table column used to display actions.
 */
- (void) setActionColumn: (NSTableColumn *)ac;
/**
 * Returns the table column used to display outlets.
 */
- (NSTableColumn *)outletColumn;
/**
 * Sets the table column used to display outlets.
 */
- (void) setOutletColumn: (NSTableColumn *)oc;
/**
 * Returns the menu item associated with the current context menu.
 */
- (NSMenuItem *)menuItem;
/**
 * Sets the menu item associated with the current context menu.
 */
- (void) setMenuItem: (NSMenuItem *)item;
/**
 * Returns the current attribute type being edited (none, outlets, or actions).
 */
- (GSAttributeType)editType;
/**
 * Removes the item displayed at the specified row index.
 */
- (void) removeItemAtRow: (int)row;
/**
 * Resets the view by clearing editing state and reloading data.
 */
- (void) reset;
/**
 * Selects the specified row in the outline view.
 */
- (void) selectRow: (int)rowIndex;
@end /* interface of GormOutlineView */

// informal protocol to define necessary methods on
// GormOutlineView's data source to make information
// about the class which was selected...
/**
 * Data source additions that provide actions and outlets for items in the outline view.
 */
@interface NSObject (GormOutlineViewDataSource)
/**
 * Returns an array of action names for the specified item.
 */
- (NSArray *) outlineView: (GormOutlineView *)ov
           actionsForItem: (id)item;
/**
 * Returns an array of outlet names for the specified item.
 */
- (NSArray *) outlineView: (GormOutlineView *)ov
           outletsForItem: (id)item;
/**
 * Adds the specified action to the given class representation.
 */
- (void)outlineView: (NSOutlineView *)anOutlineView
	  addAction: (NSString *)action
           forClass: (id)item;
/**
 * Adds the specified outlet to the given class representation.
 */
- (void)outlineView: (NSOutlineView *)anOutlineView
	  addOutlet: (NSString *)outlet
           forClass: (id)item;
/**
 * Adds a new action to the given class and returns its generated name.
 */
- (NSString *)outlineView: (NSOutlineView *)anOutlineView
     addNewActionForClass: (id)item;
/**
 * Adds a new outlet to the given class and returns its generated name.
 */
- (NSString *)outlineView: (NSOutlineView *)anOutlineView
     addNewOutletForClass: (id)item;
@end

/**
 * Delegate additions used to control editing behavior for items.
 */
@interface NSObject (GormOutlineViewDelegate)
/**
 * Returns YES to allow deletion of the specified item; NO to disallow.
 */
- (BOOL) outlineView: (GormOutlineView *)ov
    shouldDeleteItem: (id)item;
@end

// a class to hold the outlet/actions so that the
// draw row method will know how to render them on
// the display...
/**
 * GormOutletActionHolder is a simple value object that stores the display
 * name of an outlet or action row for rendering in the outline view.
 */
@interface GormOutletActionHolder : NSObject
{
  NSString *_name;
}
- initWithName: (NSString *)name;
/**
 * Returns the display name of the item.
 */
- (NSString *)getName;
/**
 * Sets the display name of the item.
 */
- (void)setName: (NSString *)name;
@end
#endif /* _GNUstep_H_GormOutlineView */
