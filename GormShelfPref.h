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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifndef GORMSHELFPREF_H
#define GORMSHELFPREF_H

#include <AppKit/NSView.h>
#include <Foundation/NSObject.h>

typedef enum { 
	leftarrow,
	rightarrow
} ArrowPosition;

@class NSEvent;
@class NSNotification;

@interface ArrResizer : NSView
{
  NSImage *arrow;
  ArrowPosition position;
  id controller;
}

- (id)initForController:(id)acontroller 
           withPosition:(ArrowPosition)pos;

- (ArrowPosition)position;

@end

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

- (void)tile;
- (void)selectionChanged:(NSNotification *)n;
- (void)startMouseEvent:(NSEvent *)event 
              onResizer:(ArrResizer *)resizer;
- (void)setNewWidth:(int)w;
- (IBAction)setDefaultWidth:(id)sender;
- (NSView *)view;
- (int) shelfCellsWidth;
@end

#endif 
