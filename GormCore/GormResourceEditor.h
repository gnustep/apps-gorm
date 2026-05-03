/* GormResourceEditor.h
 *
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2005
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

#ifndef INCLUDED_GormResourceEditor_h
#define INCLUDED_GormResourceEditor_h

#include "GormGenericEditor.h"

@interface GormResourceEditor : GormGenericEditor
/**
 * Notifies the editor when a drag operation of an image ends, including the
 * final position and whether the drop was accepted.
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
/**
 * Returns the drag operation mask (copy, move, etc.) supported by the editor
 * for local or external drags depending on the flag.
 */
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
/**
 * Refreshes the resource cells to reflect any changes in the underlying data
 * or selection.
 */
- (void) refreshCells;
/**
 * Creates and returns a GormResource placeholder object for the specified
 * path.
 */
- (id) placeHolderWithPath: (NSString *)path;
/**
 * Returns the array of supported pasteboard types for resources handled by
 * this editor.
 */
- (NSArray *) pbTypes;
/**
 * Returns a string identifier for the type of resources managed by this
 * editor.
 */
- (NSString *) resourceType;
/**
 * Adds built‑in system resources to the editor so they are available for use
 * within the document.
 */
- (void) addSystemResources;
@end

#endif
