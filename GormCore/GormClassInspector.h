/** <title>GormClassInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: September 2002

   This file is part of GNUstep.

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

/* All Rights reserved */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

@class GormClassManager;

/**
 * GormClassInspector provides an inspector interface that allows users to
 * select and modify custom classes, their actions, and outlets within a
 * Gorm document.
 */
@interface GormClassInspector : IBInspector
{
  // outlets
  id _actionTable; 
  id _addAction;
  id _addOutlet;
  id _classField;
  id _outletTable;
  id _parentClass;
  id _removeAction;
  id _removeOutlet;
  id _selectClass;
  id _search;
  id _searchText;
  id _tabView;

  // internal vars
  NSString *_currentClass;
  id _theobject;
  id _actionData;
  id _outletData;
  id _parentClassData;

  // class manager..
  GormClassManager *_classManager;
}

/**
 * Adds a new action to the currently selected class.
 */
- (void) addAction: (id)sender;

/**
 * Removes the selected action from the currently selected class.
 */
- (void) removeAction: (id)sender;

/**
 * Adds a new outlet to the currently selected class.
 */
- (void) addOutlet: (id)sender;

/**
 * Removes the selected outlet from the currently selected class.
 */
- (void) removeOutlet: (id)sender;

/**
 * Selects the class for the current object.
 */
- (void) select: (id)sender;

/**
 * Initiates a search for a class by name.
 */
- (void) searchForClass: (id)sender;

/**
 * Selects a class from the class list.
 */
- (void) selectClass: (id)sender;

/**
 * Returns the name of the currently selected class.
 */
- (NSString *) _currentClass;

/**
 * Refreshes the inspector view to reflect current class information.
 */
- (void) _refreshView;

/**
 * Handles notifications related to class changes.
 */
- (void) handleNotification: (NSNotification *)notification;

/**
 * Changes the class name of the inspected object.
 */
- (void) changeClassName: (id)sender;

/**
 * Handles selection of an action in the action table.
 */
- (void) selectAction: (id)sender;

/**
 * Handles selection of an outlet in the outlet table.
 */
- (void) selectOutlet: (id)sender;
@end
