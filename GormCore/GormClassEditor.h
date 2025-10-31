/* GormClassEditor.h
 *
 * Copyright (C) 1999, 2003, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2005
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

#ifndef INCLUDED_GormClassEditor_h
#define INCLUDED_GormClassEditor_h

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

#include <GormCore/GormOutlineView.h>

@class NSString, NSArray, GormDocument, GormClassManager, NSBrowser;

/** Pasteboard type for class dragging operations. */
extern NSString *GormClassPboardType;

/** Notification posted when switching between outline and browser views. */
extern NSString *GormSwitchViewPreferencesNotification;

/**
 * GormClassEditor provides the interface for viewing and editing class
 * definitions within a Gorm document. It supports both outline and browser
 * views for class hierarchies and allows manipulation of class attributes
 * such as outlets and actions.
 */
@interface GormClassEditor : NSView <IBEditors, IBSelectionOwners>
{
  GormDocument          *document;
  GormClassManager      *classManager;
  NSString              *selectedClass;
  NSScrollView          *scrollView;
  GormOutlineView       *outlineView;
  NSBrowser             *browserView;
  id                     classesView;
  id                     mainView;
  id                     viewToggle;
}

/**
 * Initializes the class editor with the specified document.
 */
- (GormClassEditor*) initWithDocument: (GormDocument*)doc;

/**
 * Returns a class editor instance for the specified document.
 */
+ (GormClassEditor*) classEditorForDocument: (GormDocument*)doc;

/**
 * Sets the currently selected class name.
 */
- (void) setSelectedClassName: (NSString*)cn;

/**
 * Returns the name of the currently selected class.
 */
- (NSString *) selectedClassName;

/**
 * Selects the class associated with the given object and optionally enters
 * edit mode.
 */
- (void) selectClassWithObject: (id)obj editClass: (BOOL)flag;

/**
 * Selects the class associated with the given object.
 */
- (void) selectClassWithObject: (id)obj;

/**
 * Selects the class with the specified name and optionally enters edit mode.
 */
- (void) selectClass: (NSString *)className editClass: (BOOL)flag;

/**
 * Selects the class with the specified name.
 */
- (void) selectClass: (NSString *)className;

/**
 * Returns YES if the current selection is a class, NO otherwise.
 */
- (BOOL) currentSelectionIsClass;

/**
 * Enters edit mode for the currently selected class.
 */
- (void) editClass;

/**
 * Adds a new attribute (outlet or action) to the currently selected class.
 */
- (void) addAttributeToClass;

/**
 * Deletes the currently selected class or attribute.
 */
- (void) deleteSelection;

/**
 * Returns an array of file types supported by the class editor.
 */
- (NSArray *) fileTypes;

/**
 * Reloads the class data from the document.
 */
- (void) reloadData;

/**
 * Returns YES if the editor is currently in editing mode, NO otherwise.
 */
- (BOOL) isEditing;

/**
 * Creates an instance of the currently selected class.
 */
- (id) instantiateClass: (id)sender;

/**
 * Creates a new subclass of the currently selected class.
 */
- (id) createSubclass: (id)sender;

/**
 * Loads a class from header files into the document.
 */
- (id) loadClass: (id)sender;

/**
 * Creates header and implementation files for the currently selected class.
 */
- (id) createClassFiles: (id)sender;

/**
 * Removes the currently selected class from the document.
 */
- (id) removeClass: (id)sender;
@end

#endif
