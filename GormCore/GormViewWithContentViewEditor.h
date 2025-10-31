/* GormViewWithContentViewEditor.h
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
#ifndef	INCLUDED_GormViewWithContentViewEditor_h
#define	INCLUDED_GormViewWithContentViewEditor_h

#include <GormCore/GormViewWithSubviewsEditor.h>

@class GormInternalViewEditor;

/**
 * GormViewWithContentViewEditor handles editing of views that have a dedicated content view, such as NSScrollView and NSSplitView.
 */
@interface GormViewWithContentViewEditor : GormViewWithSubviewsEditor
{
  GormInternalViewEditor *contentViewEditor;
}

/**
 * Performs post-drawing operations for the specified view editor, such as drawing selection handles.
 */
- (void) postDrawForView: (GormViewEditor *) viewEditor;
/**
 * Groups the currently selected views by placing them into a new NSSplitView container.
 */
- (void) groupSelectionInSplitView;
/**
 * Groups the currently selected views by placing them into a new NSBox container.
 */
- (void) groupSelectionInBox;
/**
 * Groups the currently selected views by placing them into a new NSMatrix container.
 */
- (void) groupSelectionInMatrix;
/**
 * Groups the currently selected views by placing them into a new generic NSView container.
 */
- (void) groupSelectionInView;
/**
 * Ungroups the selected container view, removing the container and promoting its subviews to the parent.
 */
- (void) ungroup;
/**
 * Pastes objects from the pasteboard into the specified view as new subviews.
 */
- (void) pasteInView: (NSView *)view;
@end

#endif
