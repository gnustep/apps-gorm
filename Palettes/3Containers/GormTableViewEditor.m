/* GormTableViewEditor.m - Editor for matrices.
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

#include "../../GormPrivate.h"

#import "GormTableViewEditor.h"
#import "GormNSTableView.h"

NSString *IBTableColumnPboardType = @"IBTableColumnPboardType";

static NSCell *_editedCell;
static NSCell *_currentHeaderCell;
static NSText *_textObject;

@implementation NSScrollView (GormObjectAdditions)
- (NSString*) editorClassName
{
  if ([self documentView]
      && [[self documentView] isKindOfClass: [NSTableView class]])
    return @"GormTableViewEditor";
  else
    return [super editorClassName];
}
@end

@interface GormTableViewEditor (Private)
- (void) editHeader: (NSTableHeaderView*) th
	  withEvent: (NSEvent *) theEvent;
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

- (void) setOpened: (BOOL) flag
{
  if (flag)
    [tableView setBackgroundColor: [NSColor whiteColor]];
  else
    {
      [tableView setBackgroundColor: [NSColor controlBackgroundColor]];
      [tableView deselectAll: self];
    }
  
  [super setOpened: flag];
}

/*
 * Activate an editor - inserts it into the view hierarchy or whatever is
 * needed for the editor to be able to provide its functionality.
 * This method should be called by the document when an editor is created
 * or opened.  It should be safe to call repeatedly.
 */
- (BOOL) activate
{
  if ([super activate])
    {
      if ([_editedObject isKindOfClass: [NSScrollView class]])
	tableView = [(NSScrollView *)_editedObject documentView];
      else
	tableView = (GormNSTableView *)_editedObject;
      [tableView setAllowsColumnResizing: YES];
      [tableView setAllowsColumnSelection: YES];
      [tableView setAllowsMultipleSelection: NO];
      [tableView setAllowsEmptySelection: YES];
      [tableView setAllowsColumnReordering: YES];
      [tableView setGormDelegate: self];
      return YES;
    }
  

  return NO;
}


/*
 * Deactivate an editor - removes it from the view hierarchy so that objects
 * can be archived without including the editor.
 * This method should be called automatically by the 'close' method.
 * It should be safe to call repeatedly.
 */
- (void) deactivate
{
  if (activated == YES)
    {
      [tableView setBackgroundColor: [NSColor controlBackgroundColor]];
      if ([tableView selectedColumn] != -1)
	{
	  [tableView deselectColumn: [tableView selectedColumn]];
	}
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
      [tableView setNeedsDisplay: YES];
      [super deactivate];
    }
}

/*
 * This method deletes all the objects in the current selection in the editor.
 */
- (void) deleteSelection
{
  NSLog(@"deleteSelection");
  if ([selection count] == 0)
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
      [tableView removeTableColumn: [selection objectAtIndex: 0]];
      [tableView deselectAll: self];
      [self selectObjects: [NSArray array]];
    }
}

/*
 * This method places the current selection from the editor on the pasteboard.
 */
- (void) copySelection
{
  NSLog(@"copySelection");
  if ([[[self selection] objectAtIndex: 0] 
	isKindOfClass: [NSTableColumn class]])
    {
      [document copyObjects: [self selection]
		       type: IBTableColumnPboardType
	       toPasteboard: [NSPasteboard generalPasteboard]];
    }
  else
    {
      NSLog(@"no paste");
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
  else if ([[objects objectAtIndex: 0] isKindOfClass: [NSTableColumn class]]
	   == NO)
    {
      NSLog(@"invalid data in IBTableColumnPboardType");
      return;
    }
	    
  [tableView addTableColumn: [objects objectAtIndex: 0]];

}


- (void) mouseDown:(NSEvent*)theEvent
{
  BOOL onKnob = NO;
  id hitView;
  
  {
    if ([parent respondsToSelector: @selector(selection)] &&
	[[parent selection] containsObject: _editedObject])
      {
	IBKnobPosition	knob = IBNoneKnobPosition;
	NSPoint mouseDownPoint = 
	  [self convertPoint: [theEvent locationInWindow]
		fromView: nil];
	knob = GormKnobHitInRect([self bounds], 
				 mouseDownPoint);
	if (knob != IBNoneKnobPosition)
	  onKnob = YES;
      }
    if (onKnob == YES)
      {
	if (parent)
	  return [parent mouseDown: theEvent];
	else
	  return [self noResponderFor: @selector(mouseDown:)];
      }
  }
  
  if (opened == NO)
    {
      NSLog(@"not opened");
      [super mouseDown: theEvent];
      return;
    }


  hitView = 
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
  else if ([hitView isKindOfClass: [NSScroller class]])
    {
      [hitView mouseDown: theEvent];
    }
  else if (hitView == tableView)
    {
      if ([tableView selectedColumn] != -1)
	{
	  [tableView deselectColumn: [tableView selectedColumn]];
	}
    }
}

//  - (void) changeObject: (id)anObject
//  {
//    if (tableView != nil)
//      {
//        if ([tableView selectedColumn] != -1)
//  	{
//  	  [tableView deselectColumn: [tableView selectedColumn]];
//  	}
//        [tableView setBackgroundColor: [NSColor controlBackgroundColor]];
//      }
//    ASSIGN(tableView, anObject);

//    [tableView setBackgroundColor: [NSColor whiteColor]];
//    [tableView setNeedsDisplay: YES];
//    [self selectObjects: [NSArray arrayWithObject: tableView]];
//    [self activate];
//  }


- (void) tableViewSelectionDidChange: (id) tv
{
  if ([tableView selectedColumn] != -1)
    {
      [self selectObjects: 
	      [NSArray arrayWithObject: 
			 [[tableView tableColumns]
			   objectAtIndex: [tableView selectedColumn]]]];
    }
  else
    {
      [self selectObjects:
	      [NSArray arrayWithObject: tableView]];
    }
}


- (void) outlineViewSelectionDidChange: (id) tv
{
  if ([tableView selectedColumn] != -1)
    {
      [self selectObjects: 
	      [NSArray arrayWithObject: 
			 [[tableView tableColumns]
			   objectAtIndex: [tableView selectedColumn]]]];
    }
  else
    {
      [self selectObjects:
	      [NSArray arrayWithObject: tableView]];
    }
}

- (void) editHeader: (NSTableHeaderView*) th
	  withEvent: (NSEvent *) theEvent 
{
  NSText *t;
  NSTableColumn *tc;
  NSRect drawingRect;

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
  //  [_editedCell setAlignment: NSLeftTextAlignment];
  [(NSTableHeaderCell *)_editedCell setTextColor: [NSColor blackColor]];
  [(NSTableHeaderCell *)_editedCell setBackgroundColor: [NSColor whiteColor]];
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


//  - (NSArray*) selection
//  {
//    if (tableView == nil)
//      return [NSArray array];
//    else if (selected == nil)
//      return [NSArray arrayWithObject: tableView];
//    else
//      return [NSArray arrayWithObject: selected];
//  }

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  return [self draggingUpdated: sender];
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender

{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      id destination = nil;
      NSView *hitView = 
	[[tableView enclosingScrollView] 
	  hitTest: 
	    [[[tableView enclosingScrollView] superview]
	      convertPoint: [sender draggingLocation]
	      fromView: nil]];
      
      if (hitView == [tableView headerView])
	{
	  NSPoint p = [hitView convertPoint: [sender draggingLocation]
			       fromView: nil];
	  int columnNumber = 
	    [(NSTableHeaderView*) hitView columnAtPoint: p];
	  
	  if (columnNumber != -1)
	    destination = [[tableView tableColumns] 
			    objectAtIndex: columnNumber];
	}

      if (hitView == tableView)
	destination = tableView;

      if (destination == nil)
	destination = _editedObject;

      [NSApp displayConnectionBetween: [NSApp connectSource] 
	     and: destination];
      return NSDragOperationLink;
    }
  else
    {
      return NSDragOperationNone;
    }
}
- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      id destination = nil;
      NSView *hitView = 
	[[tableView enclosingScrollView] 
	  hitTest: 
	    [[[tableView enclosingScrollView] superview]
	      convertPoint: [sender draggingLocation]
	      fromView: nil]];
      
      if (hitView == [tableView headerView])
	{
	  NSPoint p = [hitView convertPoint: [sender draggingLocation]
			       fromView: nil];
	  int columnNumber = 
	    [(NSTableHeaderView*) hitView columnAtPoint: p];
	  
	  if (columnNumber != -1)
	    destination = [[tableView tableColumns] 
			    objectAtIndex: columnNumber];
	}

      if (hitView == tableView)
	destination = tableView;

      if (destination == nil)
	destination = _editedObject;

      [NSApp displayConnectionBetween: [NSApp connectSource] 
	     and: destination];
      [NSApp startConnecting];
      return YES;
    }
  return YES;
}

- (NSWindow *)windowAndRect: (NSRect *)prect
		  forObject: (id) object
{
  if (object == tableView)
    {
      *prect = [tableView convertRect: [tableView visibleRect]
			  toView :nil];
      return _window;
    }
  else
    {
      return [super windowAndRect: prect forObject: object];
    }
}

@end








