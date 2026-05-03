/* GormViewWithSubviewsEditor.h
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
#ifndef	INCLUDED_GormViewWithSubviewsEditor_h
#define	INCLUDED_GormViewWithSubviewsEditor_h

#include <GormCore/GormViewEditor.h>

@interface GormViewWithSubviewsEditor : GormViewEditor <IBSelectionOwners>
{
  BOOL _displaySelection;
  GormViewWithSubviewsEditor *openedSubeditor;
  NSMutableArray *selection;
  BOOL opened;
  BOOL _followGuideLine;
}

/*
 * Handle mouse click on knob.
 */
- (void) handleMouseOnKnob: (IBKnobPosition) knob
		    ofView: (GormViewEditor *) view
		 withEvent: (NSEvent *) theEvent;

/*
 * Handle mouse click on view.
 */
- (void) handleMouseOnView: (GormViewEditor *) view
		 withEvent: (NSEvent *) theEvent;

/**
 * Sets the currently opened subeditor, which is editing a subview within this editor's view.
 */
- (void) setOpenedSubeditor: (GormViewWithSubviewsEditor *) newEditor;
/**
 * Opens the parent editor of this editor, switching the editing focus to the containing view.
 */
- (void) openParentEditor;
/**
 * Makes any opened subeditor resign its editing role, closing the subview editing session.
 */
- (void) makeSubeditorResign;
/**
 * Resets the selection without triggering selection change notifications or updates.
 */
- (void) silentlyResetSelection;
/**
 * Selects the specified array of objects within this editor's view, updating the selection handles.
 */
- (void) selectObjects: (NSArray *) objects;
/**
 * Copies the currently selected objects to the pasteboard.
 */
- (void) copySelection;

/*
 * Close subeditors of this editor.
 */
- (void) closeSubeditors;
/**
 * Deactivates all currently opened subeditors, preparing them for the parent editor to deactivate.
 */
- (void) deactivateSubeditors;
/**
 * Changes the font of any selected text-bearing views in the current selection.
 */
- (void) changeFont: (id)sender;
@end

#endif
