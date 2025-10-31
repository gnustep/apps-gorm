/* GormShelfPref.h
 *  
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author: Gregory Casamento <greg_casamento@yahoo.com>
 * Date: February 2004
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: August 2001
 *
 * This class is heavily based on work done by Enrico Sersale
 * on ShelfPref.h for GWorkspace.
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifndef GORMSHELFPREF_H
#define GORMSHELFPREF_H

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

typedef enum { 
	leftarrow,
	rightarrow
} ArrowPosition;

@class NSEvent;
@class NSNotification;

/**
 * ArrResizer is an internal view that draws a grab/arrow handle used to
 * resize the shelf width in the preferences UI.
 */
@interface ArrResizer : NSView
{
  NSImage *arrow;
  ArrowPosition position;
  id controller;
}

/**
 * Initializes and returns a new instance.
 */
- (id)initForController:(id)acontroller 
           withPosition:(ArrowPosition)pos;

/**
 * The arrow position (left or right) this resizer represents.
 */
- (ArrowPosition)position;

@end

/**
 * GormShelfPref implements the Shelf preferences pane. It provides controls
 * to adjust the icon shelf width and related appearance settings, and returns
 * the view embedded in the preferences window.
 */
@interface GormShelfPref : NSObject 
{
  IBOutlet id win;
  IBOutlet id prefbox;
  IBOutlet id iconbox;
  IBOutlet id imView;
  IBOutlet id leftResBox;
  IBOutlet id rightResBox;
  IBOutlet id nameField;
  IBOutlet id setButt;

  ArrResizer *leftResizer; 
  ArrResizer *rightResizer;
  NSString *fname;    
  int cellsWidth;
}

/**
 * Sets the frame for the resize arrows.
 */
- (void)tile;

/**
 * Called when the selection is changed.
 */ 
- (void)selectionChanged:(NSNotification *)n;

/**
 * Invoked when the resizer widgets are moved.
 */
- (void)startMouseEvent:(NSEvent *)event 
              onResizer:(ArrResizer *)resizer;

/**
 * Programmatically set a width.
 */ 
- (void)setNewWidth:(int)w;

/**
 * Set the resizer back to the default width.
 */
- (IBAction)setDefaultWidth:(id)sender;

/**
 * The view to display in the prefs panel.
 */
- (NSView *)view;

/**
 * Return the current width.
 */ 
- (int) shelfCellsWidth;
@end

#endif 
