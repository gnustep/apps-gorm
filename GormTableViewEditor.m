/* GormMatrixEditor.m - Editor for matrices.
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Date:	Sep 2002
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

#include "GormPrivate.h"

NSString *IBTableColumnPboardType = @"IBTableColumnPboardType";

static NSCell *_editedCell;
static NSCell *_currentHeaderCell;
static NSText *_textObject;
static int _oldAlignment;
static NSColor *_oldColor;

@implementation NSTableView (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormTableViewEditor";
}
@end

@implementation GormTableViewEditor
/*
 * Decide whether an editor can accept data from the pasteboard.
 */
- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  // FIXME
  return NO;
}

/*
 * Activate an editor - inserts it into the view hierarchy or whatever is
 * needed for the editor to be able to provide its functionality.
 * This method should be called by the document when an editor is created
 * or opened.  It should be safe to call repeatedly.
 */
- (BOOL) activate
{
  NSLog(@"activate");

  if (tableView)
    {
      [tableView setAllowsColumnResizing: YES];
      [tableView setAllowsColumnSelection: YES];
      [tableView setAllowsMultipleSelection: NO];
      [tableView setAllowsEmptySelection: YES];
      [tableView setAllowsColumnReordering: YES];
      [tableView setGormDelegate: self];
    }
  return YES;
}

- (id) initWithObject: (id)anObject 
	   inDocument: (id/*<IBDocuments>*/)aDocument
{
  self = [super init];
  [self changeObject: anObject];
  document = aDocument;
  return self;
}

/*
 * Close an editor - this destroys the editor.  In this method the editor
 * should tell its document that it has been closed, so that the document
 * can remove all its references to the editor.
 */
- (void) close
{
  NSLog(@"close");
  if (tableView)
    {
      if ([tableView selectedColumn] != -1)
	{
	  [tableView deselectColumn: [tableView selectedColumn]];
	}
      [self closeSubeditors];
	  
      [self deactivate];
      tableView = nil;
    }
  else
    {
      NSLog(@"tableView = nil");
    }
}

/*
 * Close subeditors of this editor.
 */
- (void) closeSubeditors
{
}

/*
 * Deactivate an editor - removes it from the view hierarchy so that objects
 * can be archived without including the editor.
 * This method should be called automatically by the 'close' method.
 * It should be safe to call repeatedly.
 */
- (void) deactivate
{
  if (tableView)
    {
      [tableView setAllowsColumnResizing:
		  [tableView gormAllowsColumnResizing]];
      [tableView setAllowsColumnSelection:
		  [tableView gormAllowsColumnSelection]];
      [tableView setAllowsMultipleSelection:
		  [tableView gormAllowsMultipleSelection]];
      [tableView setAllowsEmptySelection:
		  [tableView gormAllowsEmptySelection]];
      [tableView setAllowsColumnReordering:
		  [tableView gormAllowsColumnReordering]];
      [tableView setGormDelegate: nil];
    }
  NSLog(@"deactivate");
  selected = nil;
}

/*
 * This method deletes all the objects in the current selection in the editor.
 */
- (void) deleteSelection
{
  NSLog(@"deleteSelection");
  if (selected == nil)
    {
      NSLog(@"no column to delete");
    }
  if ([tableView numberOfColumns] <= 1)
    {
      NSLog(@"can't delete last column");
    }
  else
    {
      NSLog(@"FIXME: remove the tableColumn from toplevel"); // FIXME
      [tableView removeTableColumn: selected];
      [document detachObject: selected];
      [tableView deselectAll: self];
      selected = nil;
    }
}

/*
 * This method places the current selection from the editor on the pasteboard.
 */
- (void) copySelection
{
  NSLog(@"copySelection");
  if (selected != nil)
    {
      [document copyObjects: [self selection]
		       type: IBTableColumnPboardType
	       toPasteboard: [NSPasteboard generalPasteboard]];
    }
}

/*
 * This method is used to add the contents of the pasteboard to the current
 * selection of objects within the editor.
 */
- (void) pasteInSelection
{
  NSArray *objects;
  NSLog(@"pasteInSelection");
  

  objects = [document pasteType: IBTableColumnPboardType
                 fromPasteboard: [NSPasteboard generalPasteboard]
	                 parent: nil];

  if (objects == nil)
    return;

  if ([objects count] == 0)
    return;

  if ([objects count] > 1)
    {
      NSLog(@"warning strange behaviour : GormTableViewEditor pasteInSelection");
    }
	    
  [tableView addTableColumn: [objects objectAtIndex: 0]];

}

/*
 * This method returns the document that owns the object that the editor edits.
 */
- (id /*<IBDocuments>*/) document
{
  return document;
}

/*
 * This method returns the object that the editor is editing.
 */
- (id) editedObject
{
  return tableView;
}

/*
 * This method is used to draw or remove markup that identifies selected
 * objects within the object being edited.
 */
- (void) makeSelectionVisible: (BOOL)flag
{
  NSLog(@"makeSelectionVisible");
  // FIXME
}

/*
 * This method is used to open an editor for an object within the object
 * currently being edited.
 */
- (id<IBEditors>) openSubeditorForObject: (id)anObject
{
  // FIXME
  return nil;
}

/*
 * This method is used to ensure that the editor is visible on screen.
 */
- (void) orderFront
{
  // FIXME
}

/*
 * FIXME - I don't think we use this.
 */
- (void) resetObject: (id)anObject
{
  // FIXME
}

/*
 * This method changes the current selection to those objects in the array.
 */
- (void) selectObjects: (NSArray*)anArray
{
  id	obj = [anArray lastObject];
  NSLog(@"selectObjects");
  [self makeSelectionVisible: NO];
  selected = obj;
  [document setSelectionFromEditor: self];
  [self makeSelectionVisible: YES];
  // FIXME
}

/*
 * FIXME - I don't think we use this.
 */
- (void) validateEditing
{
  // FIXME
}

/*
 * When an editor resigns the selection ownership, all editors are asked if
 * they want selection ownership, and the first one to return YES gets made
 * into the current selection owner.
 */
- (BOOL) wantsSelection
{
  return NO;
}

/*
 * This returns the window in which the editor is drawn.
 */
- (NSWindow*) window
{
  return nil;
}


- (void) mouseDown:(NSEvent*)theEvent
{
  id hitView = 
    [[tableView enclosingScrollView] 
      hitTest: 
	[[[tableView enclosingScrollView] superview]
	  convertPoint: [theEvent locationInWindow]
	  fromView: nil]];

  if (hitView == [tableView headerView])
    {
      if ([theEvent clickCount] == 2)
	{
	  [self editHeader: hitView
		withEvent: theEvent];
	}
      else
	{
	  [hitView mouseDown: theEvent];
	}
    }
}

- (void) changeObject: (id)anObject
{
  ASSIGN(tableView, anObject);
  [self activate];
}


- (void) tableViewSelectionDidChange: (id) tv
{
  if ([tableView selectedColumn] != -1)
    {
      selected = [[tableView tableColumns]
		   objectAtIndex: [tableView selectedColumn]];
      [self selectObjects: 
	      [NSArray arrayWithObject: selected]];
    }
  else
    {
      NSLog(@"no selection");
    }
}


- (void) outlineViewSelectionDidChange: (id) tv
{
  if ([tableView selectedColumn] != -1)
    {
      selected = [[tableView tableColumns]
		   objectAtIndex: [tableView selectedColumn]];
      [self selectObjects: 
	      [NSArray arrayWithObject: selected]];
    }
  else
    {
      NSLog(@"no selection");
    }
}

- (void) editHeader: (NSTableHeaderView*) th
	  withEvent: (NSEvent *) theEvent 
{
  NSText *t;
  NSTableColumn *tc;
  NSRect drawingRect;
  unsigned length = 0;

  int columnIndex = [th columnAtPoint: 
			  [th convertPoint:[theEvent locationInWindow]
			      fromView: nil]];
  
  if (columnIndex == NSNotFound)
    return; 

  _textObject = nil;

  [[th tableView] scrollColumnToVisible: columnIndex];

  

  t = [[th window] fieldEditor: YES  forObject: self];

  if ([t superview] != nil)
    {
      if ([t resignFirstResponder] == NO)
	{
	  return;
	}
    }
  

  // Prepare the cell
  tc = [[tableView tableColumns] objectAtIndex: columnIndex];
  // NB: need to be released when no longer used
  _editedCell = [[tc headerCell] copy];
  _currentHeaderCell = [tc headerCell];
  [_editedCell setStringValue: [[tc headerCell] stringValue]];
  [_editedCell setEditable: YES];
  [_editedCell setAlignment: NSLeftTextAlignment];
  [_editedCell setTextColor: [NSColor blackColor]];
  [_editedCell setBackgroundColor: [NSColor whiteColor]];
  _textObject = [_editedCell setUpFieldEditorAttributes: t];

  drawingRect = [th headerRectOfColumn: columnIndex];
  [_editedCell editWithFrame: drawingRect
	       inView: th
	       editor: _textObject
	       delegate: self
	       event: theEvent];
  return;    
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  [_editedCell endEditing: _textObject];
  [_currentHeaderCell setStringValue: [[_textObject text] copy]];

  RELEASE(_editedCell);
}


- (NSArray*) selection
{
  if (selected == nil)
    return [NSArray array];
  else
    return [NSArray arrayWithObject: selected];
}

- (unsigned) selectionCount
{
  return (selected == nil) ? 0 : 1;
}

- (void) drawSelection
{
}

@end








