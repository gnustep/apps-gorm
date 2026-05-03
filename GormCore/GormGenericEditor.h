/* GormGenericEditor.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2004
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

#ifndef INCLUDED_GormGenericEditor_h
#define INCLUDED_GormGenericEditor_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

/**
 * GormGenericEditor provides a generic matrix-based editor for managing
 * collections of objects within a Gorm document. It is used as a base editor
 * for displaying and managing lists of objects such as images, sounds, and
 * custom classes.
 */
@interface GormGenericEditor : NSMatrix <IBEditors, IBSelectionOwners>
{
  NSMutableArray	*objects;
  id<IBDocuments>	document;
  id			selected;
  NSPasteboard		*dragPb;
  NSString		*dragType;
  BOOL                  closed;
  BOOL                  activated;
  IBResourceManager     *resourceManager;
}

/**
 * Returns the editor instance for the specified document.
 */
+ (id) editorForDocument: (id<IBDocuments>)aDocument;

/**
 * Associates the specified editor with the given document.
 */
+ (void) setEditor: (id)editor
       forDocument: (id<IBDocuments>)aDocument; 

// selection methods...
/**
 * Selects the specified object or objects in the matrix and updates selection highlighting.
 */
- (void) selectObjects: (NSArray*)objects;
/**
 * Returns YES if this editor participates in selection ownership and wants to receive selection updates.
 */
- (BOOL) wantsSelection;
/**
 * Copies the current selection to the pasteboard.
 */
- (void) copySelection;
/**
 * Deletes the currently selected objects from the editor.
 */
- (void) deleteSelection;
/**
 * Pastes objects from the pasteboard into the current selection context.
 */
- (void) pasteInSelection;
/**
 * Refreshes the matrix cells to reflect the current objects and selection.
 */
- (void) refreshCells;
/**
 * Closes any subeditors opened by this editor.
 */
- (void) closeSubeditors;

/**
 * Returns the window containing this editor.
 */
- (NSWindow*) window;
/**
 * Adds an object to the collection.
 */
- (void) addObject: (id)anObject;
/**
 * Refreshes the matrix cells to reflect the current objects and selection.
 */
- (void) refreshCells;
/**
 * Removes an object from the collection.
 */
- (void) removeObject: (id)anObject;
/**
 * Activates the editor and makes it ready for use.
 */
- (BOOL) activate;
/**
 * Initializes and returns a new instance.
 */
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
/**
 * Closes the editor and releases its resources.
 */
- (void) close;
/**
 * Closes any subeditors opened by this editor.
 */
- (void) closeSubeditors;
/**
 * Returns YES if the editor contains the specified object; NO otherwise.
 */
- (BOOL) containsObject: (id)anObject;
/**
 * Copies the current selection to the pasteboard.
 */
- (void) copySelection;
/**
 * Deletes the currently selected objects from the editor.
 */
- (void) deleteSelection;
/**
 * Returns the document that owns this editor.
 */
- (id<IBDocuments>) document;
/**
 * Returns the object being edited by this editor.
 */
- (id) editedObject;
/**
 * Opens a subeditor to edit the specified object and returns it.
 */
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
/**
 * Brings the editor window to the front.
 */
- (void) orderFront;
/**
 * Pastes objects from the pasteboard into the current selection context.
 */
- (void) pasteInSelection;
/**
 * Returns the rectangle, in this editor's coordinate space, that corresponds to the specified object.
 */
- (NSRect) rectForObject: (id)anObject;

/**
 * Returns the array of objects displayed by this editor.
 */
- (NSArray *) objects;
/**
 * Returns YES if the editor window is open; NO otherwise.
 */
- (BOOL) isOpened;
/**
 * Returns an array of file types this editor can import or handle.
 */
- (NSArray *) fileTypes;
@end

// private methods...
/**
 * Private methods used by GormGenericEditor to manage lifecycle events,
 * grouping and ungrouping operations, and document notifications.
 */
@interface GormGenericEditor (PrivateMethods)
/**
 * Handles document-will-close notifications and closes the editor.
 */
- (void) willCloseDocument: (NSNotification *) aNotification;
/**
 * Groups the selected views by placing them into a new NSScrollView.
 */
- (void) groupSelectionInScrollView;
/**
 * Groups the selected views by placing them into a new NSSplitView.
 */
- (void) groupSelectionInSplitView;
/**
 * Groups the selected views by placing them into a new NSBox.
 */
- (void) groupSelectionInBox;
/**
 * Groups the selected views by placing them into a new generic NSView.
 */
- (void) groupSelectionInView;
/**
 * Groups the selected views by placing them into a new NSMatrix.
 */
- (void) groupSelectionInMatrix;
/**
 * Ungroups the selected container view, promoting its subviews to the parent.
 */
- (void) ungroup;
/**
 * Sets the editor instance for the specified document.
 */
- (void) setEditor: (id)anEditor forDocument: (id<IBDocuments>)doc;
/**
 * Changes the current selection based on the sender (menu or UI action).
 */
- (id) changeSelection: (id)sender;
@end

#endif
