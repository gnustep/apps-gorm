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
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
#import "GormViewWithSubviewsEditor.h"

@class GormInternalViewEditor;

@interface GormViewWithContentViewEditor : GormViewWithSubviewsEditor
{
  GormInternalViewEditor *contentViewEditor;
}

- (void) handleMouseOnKnob: (IBKnobPosition) knob
		    ofView: (GormViewEditor *) view
		 withEvent: (NSEvent *) theEvent;

- (void) handleMouseOnView: (GormViewEditor *) view
		 withEvent: (NSEvent *) theEvent;
- (void) postDrawForView: (GormViewEditor *) viewEditor;
- (void) groupSelectionInSplitView;
- (void) groupSelectionInBox;
- (void) ungroup;
- (void) pasteInView: (NSView *)view;
@end
