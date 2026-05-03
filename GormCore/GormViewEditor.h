/* GormViewEditor.h
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Date:	2002
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

#include <InterfaceBuilder/InterfaceBuilder.h>

#ifndef	INCLUDED_GormViewEditor_h
#define	INCLUDED_GormViewEditor_h

@class GormViewWithSubviewsEditor;
@class GormPlacementInfo;
@class GormViewWindow;

/**
 * GormViewEditor provides the base editor class for editing NSView and its subclasses within the Gorm interface builder. It handles view selection, manipulation, and subview management.
 */
@interface GormViewEditor : NSView <IBEditors>
{
  id<IBDocuments>	            document;
  id		                    _editedObject;
  BOOL                              activated;
  BOOL                              closed;
  GormViewWithSubviewsEditor        *parent;
  GormViewWindow                    *viewWindow;
}
/**
 * Activates the editor and makes it ready for use.
 */
- (BOOL) activate;
/**
 * Initializes and returns a new instance.
 */
- (id) initWithObject: (id)anObject 
	   inDocument: (id<IBDocuments>)aDocument;
/**
 * Closes the editor and releases its resources.
 */
- (void) close;
/**
 * Deactivates the editor and removes it from the view hierarchy.
 */
- (void) deactivate;
/**
 * Returns the document that owns this editor.
 */
- (id<IBDocuments>) document;
/**
 * Returns the object being edited.
 */
- (id) editedObject;
/**
 * Detaches subviews from the edited view.
 */
- (void) detachSubviews;
/**
 * Performs post-draw operations after the view is drawn.
 */
- (void) postDraw: (NSRect) rect;
/**
 * Returns the parent editor if this is a subeditor.
 */
- (id) parent;
/**
 * Returns an array of currently selected objects.
 */
- (NSArray *) selection;
/**
 * Selects the specified object or objects.
 */
- (void) makeSelectionVisible: (BOOL) value;
/**
 * Returns YES if the condition is true, NO otherwise.
 */
- (BOOL) isOpened;
/**
 * Returns the canBeOpened.
 */
- (BOOL) canBeOpened;
/**
 * Sets the property value.
 */
- (void) setOpened: (BOOL) value;
/**
 * Called when the frame of the edited view changes.
 */
- (void) frameDidChange: (id) sender;
@end

/**
 * GormViewEditor provides the base editor class for editing NSView and its subclasses within the Gorm interface builder. It handles view selection, manipulation, and subview management.
 */
@interface GormViewEditor (EditingAdditions)
/**
 * Begins editing a text field in response to an event.
 */
- (NSEvent *) editTextField: view withEvent: (NSEvent *)theEvent;
@end

/**
 * GormViewEditor provides the base editor class for editing NSView and its subclasses within the Gorm interface builder. It handles view selection, manipulation, and subview management.
 */
@interface GormViewEditor (IntelligentPlacement)
/**
 * Initializes and returns a new instance.
 */
- (GormPlacementInfo *) initializeResizingInFrame: (NSView *)view
						    withKnob: (IBKnobPosition) knob;
/**
 * Updates the object's state.
 */
- (void) updateResizingWithFrame: (NSRect) frame
			andEvent: (NSEvent *)theEvent
		andPlacementInfo: (GormPlacementInfo*) gpi;
/**
 * Validate a proposed frame during interactive placement and update snapping
 * based on the current placement hints and event state.
 */
- (void) validateFrame: (NSRect) frame
	     withEvent: (NSEvent *) theEvent
      andPlacementInfo: (GormPlacementInfo*)gpi;
@end

/**
 * GormViewEditor provides the base editor class for editing NSView and its subclasses within the Gorm interface builder. It handles view selection, manipulation, and subview management.
 */
@interface GormViewEditor (WindowAndRect)
/*
 * Pull the window object and it's rect.
 */
- (NSWindow *)windowAndRect: (NSRect *)prect
                  forObject: (id) object;
@end

#endif
