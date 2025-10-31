/* GormObjectEditor.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	1999, 2003, 2004, 2024
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

#ifndef INCLUDED_GormObjectEditor_h
#define INCLUDED_GormObjectEditor_h

#import "GormGenericEditor.h"

@interface NSObject (GormObjectAdditions)

/**
 * Returns the icon image to display for this object in the objects viewer panel.
 */
- (NSImage *) imageForViewer;
/**
 * Returns the class name of the inspector to use when this object is selected.
 */
- (NSString *) inspectorClassName;
/**
 * Returns the class name of the connections inspector to use for this object.
 */
- (NSString *) connectInspectorClassName;
/**
 * Returns the class name of the size inspector to use for this object.
 */
- (NSString *) sizeInspectorClassName;
/**
 * Returns the class name of the help inspector to use for this object.
 */
- (NSString *) helpInspectorClassName;
/**
 * Returns the class name of the class inspector to use for this object.
 */
- (NSString *) classInspectorClassName;
/**
 * Returns the class name of the editor to use when opening this object for editing.
 */
- (NSString *) editorClassName;

@end

/**
 * GormObjectEditor provides the main objects panel editor that displays and manages all top-level objects in a Gorm document.
 */
@interface GormObjectEditor : GormGenericEditor 

/**
 * Class method that registers the specified editor instance as the object editor for the given document.
 */
+ (void) setEditor: (id)editor forDocument: (id<IBDocuments>)aDocument;
/**
 * Called when a dragged image operation completes, indicating whether the drag was deposited successfully.
 */
- (void) draggedImage: (NSImage *)i endedAt: (NSPoint)p deposited: (BOOL)f;
/**
 * Returns the drag operation mask indicating what drag operations this editor supports for local or remote drags.
 */
- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL)flag;
/**
 * Returns YES if this editor accepts drags containing any of the specified pasteboard types.
 */
- (BOOL) acceptsTypeFromArray: (NSArray *)types;
/**
 * Makes the current selection visible in the viewer, scrolling if necessary when flag is YES.
 */
- (void) makeSelectionVisible: (BOOL)flag;
/**
 * Resets the display representation of the specified object, refreshing its icon and label in the objects viewer.
 */
- (void) resetObject: (id)anObject;

@end

#endif
