/* GormMatrixEditor.m - Editor for matrices.
 *
 * Copyright (C) 2001 Free Software Foundation, Inc.
 *
 * Author:	Adam Fedor <fedor@gnu.org>
 * Date:	Sep 2001
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

@implementation NSMatrix (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormMatrixEditor";
}
@end

@interface NSForm (GormAdditions)
- (float) titleWidth;
@end

@implementation NSForm (GormAdditions)

- (float)titleWidth
{
  int i, count = [self numberOfRows];
  float new_title_width = 0;
  float candidate_title_width = 0;

  // Compute max of title width in the cells
  for (i = 0; i < count; i++)
    {
      candidate_title_width = [_cells[i][0] titleWidth];
      if (candidate_title_width > new_title_width)  
	new_title_width = candidate_title_width;
    }
  return new_title_width;
}

@end

@implementation	GormMatrixEditor

static NSMapTable	*docMap = 0;

+ (void) initialize
{
  if (self == [GormMatrixEditor class])
    {
      docMap = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,
	NSObjectMapValueCallBacks, 2);
    }
}

- (id) changeSelection: (id)sender
{
  return nil;
}

- (void) copySelection
{
  if (selected != nil)
    {
      [document copyObjects: [self selection]
		       type: IBViewPboardType
	       toPasteboard: [NSPasteboard generalPasteboard]];
    }
}

- (void) dealloc
{
  RELEASE(matrix);
  [super dealloc];
}

- (void) deleteSelection
{
  NSLog(@"Cannot delete Matrix cell\n");
}

static BOOL done_editing;

- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];
  if ([name isEqual: NSControlTextDidEndEditingNotification] == YES)
    {
      done_editing = YES;
    }
  else
    NSLog(@"GormMatrixEditor got unhandled notification %@", name);
}

- (id) editedObject
{
  return matrix;
}

/*
 *	Initialisation
 */
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  id	old = NSMapGet(docMap, (void*)aDocument);

  if (old != nil)
    {
      RELEASE(self);
      self = RETAIN(old);
      [self changeObject: anObject];
      return self;
    }

  self = [super init];
  if (self != nil)
    {
      document = aDocument;
      NSMapInsert(docMap, (void*)aDocument, (void*)self);
      [self changeObject: anObject];
    }
  return self;
}

/* Called when we double-click on a text/editable cell or form. Overlay
   a text field so the user can edit the title.
   FIXME: Only works with NSForms now, doesn't handle different fonts
   or cell sizes, etc. Needs some work.*/
- (void) editTitleWithEvent: (NSEvent *)theEvent
{
  int row, col;
  unsigned eventMask;
  id edit_view;
  BOOL isForm;
  NSRect                 frame;
  NSTextField           *editField;
  NSDate		*future = [NSDate distantFuture];
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  isForm = [matrix isKindOfClass: [NSForm class]];
  if (isForm == NO && [selected type] != NSTextCellType)
    return;

  /* FIXME: Seems wierd to do this. */
  edit_view = [matrix superview];

  [matrix getRow: &row column: &col ofCell: selected];
  frame = [matrix cellFrameAtRow: row column: col];
  frame.origin.x += NSMinX([matrix frame]);
  if (isForm)
    frame.size.width = [(NSForm *)matrix titleWidth];
  else
    frame = [selected titleRectForBounds: frame];
  if ([matrix isFlipped])
    {
      frame.origin.y = NSMaxY([matrix frame]) - NSMaxY(frame);
    }
  else
    {
      frame.origin.y = NSMinY([matrix frame]) + NSMinY(frame);
    }

  /* Now create an edit field and allow the user to edit the text */
  editField = [[NSTextField alloc] initWithFrame: frame];
  [editField setEditable: YES];
  [editField setSelectable: YES];
  [editField setBezeled: NO];
  [editField setEnabled: YES];
  if (isForm)
    [editField setStringValue: [(NSFormCell *)selected title]];
  else
    [editField setStringValue: [selected stringValue]];
  [edit_view addSubview: editField];
  [edit_view displayRect: frame];
  [nc addObserver: self
         selector: @selector(handleNotification:)
             name: NSControlTextDidEndEditingNotification
           object: nil];

  /* Do some modal editing */
  [editField selectText: self];
  eventMask = NSLeftMouseDownMask |  NSLeftMouseUpMask  |
  NSKeyDownMask  |  NSKeyUpMask  | NSFlagsChangedMask;

  done_editing = NO;
  while (!done_editing)
    {
      NSEvent *e;
      NSEventType eType;
      e = [NSApp nextEventMatchingMask: eventMask
		 untilDate: future
		 inMode: NSEventTrackingRunLoopMode
		 dequeue: YES];
      eType = [e type];
      switch (eType)
	{
	case NSLeftMouseDown:
	  {
	    NSPoint dp =  [edit_view convertPoint: [e locationInWindow]
				fromView: nil];
	    if (NSMouseInRect(dp, frame, NO) == NO)
	      {
		done_editing = YES;
		break;
	      }
	  }
	  [[editField currentEditor] mouseDown: e];
	  break;
	case NSLeftMouseUp:
	  [[editField currentEditor] mouseUp: e];
	  break;
	case NSLeftMouseDragged:
	  [[editField currentEditor] mouseDragged: e];
	  break;
	case NSKeyDown:
	  [[editField currentEditor] keyDown: e];
	  break;
	case NSKeyUp:
	  [[editField currentEditor] keyUp: e];
	  break;
	case NSFlagsChanged:
	  [[editField currentEditor] flagsChanged: e];
	  break;
	default:
	  NSLog(@"Internal Error: Unhandled event during editing: %@", e);
	  break;
	}
    }

  [nc removeObserver: self
                name: NSControlTextDidEndEditingNotification
              object: nil];

  [self makeSelectionVisible: NO];
  if (isForm)
    {
      /* Set the new title and resize the form to match the titles */
      float oldTitleWidth, titleWidth;
      NSRect oldFrame;
      oldTitleWidth = [(NSForm *)matrix titleWidth];
      [(NSFormCell *)selected setTitle: [editField stringValue]];
      [(NSForm *)matrix calcSize];
      titleWidth = [(NSForm *)matrix titleWidth];
      oldFrame = frame = [matrix frame];
      frame.origin.x -= (titleWidth - oldTitleWidth);
      frame.size.width += (titleWidth - oldTitleWidth);
      [(NSForm *)matrix setEntryWidth: NSWidth(frame)];
      [(NSForm *)matrix setFrame: frame];
      frame = NSUnionRect(frame, oldFrame);
    }
  else
    [selected setStringValue: [editField stringValue]];
  
  [edit_view removeSubview: editField];
  [edit_view displayRect: frame];
  [self makeSelectionVisible: YES];

  RELEASE(editField);
}

- (void) mouseDown: (NSEvent*)theEvent
{
  int	row, col;
  id	obj;
  NSPoint loc = [theEvent locationInWindow];

  /*
   * Double-click on a cell allows one to edit the cell title
   */
  if (selected != nil && ([theEvent clickCount] == 2) )
    {
      [self editTitleWithEvent: theEvent];
      return;
    }

  /* Find which cell the mouse is in */
  loc = [matrix convertPoint: loc fromView: nil];
  if ([matrix getRow: &row column: &col forPoint: loc] == NO)
    return;

  obj = [matrix cellAtRow: row column: col];
  if (obj != nil && obj != selected)
    {
      [self selectObjects: [NSArray arrayWithObject: obj]];
    }
}

- (void) makeSelectionVisible: (BOOL)flag
{
  if (selected != nil)
    {
      int row, col;
      if ([matrix getRow: &row column: &col ofCell: selected])
	{
	  NSRect frame = [matrix cellFrameAtRow: row column: col];
	  if (flag == YES)
	    [matrix selectCellAtRow: row column: col];
	  [matrix lockFocus];
	  [[NSColor controlShadowColor] set];
	  NSHighlightRect(frame);
	  [matrix unlockFocus];
	}
    }
  else
    {
      [matrix deselectAllCells];
    }
  [matrix display];
  [[matrix window] flushWindow];
}

- (void) changeObject: anObject
{
  ASSIGN(matrix, anObject);
  selected = nil;
}

- (void) selectObjects: (NSArray*)anArray
{
  id	obj = [anArray lastObject];
  [self makeSelectionVisible: NO];
  selected = obj;
  [document setSelectionFromEditor: self];
  [self makeSelectionVisible: YES];
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

- (id<IBEditors>) openSubeditorForObject: (id)anObject
{
  return nil;
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  if ([types containsObject: IBObjectPboardType] == YES)
    return YES;
  return NO;
}

- (BOOL) activate
{
  return YES;
}

- (void) close
{
  [self deactivate];
  [self closeSubeditors];
}

- (void) closeSubeditors
{
}

- (void) deactivate
{
  selected = nil;
}

- (void) drawSelection
{
}

- (id<IBDocuments>) document
{
  return document;
}

- (void) orderFront
{
  NSLog(@"Ack - GormMatrixEditor - orderFront");
}

- (void) pasteInSelection
{
}

- (void) resetObject: (id)anObject
{
  [self changeObject: anObject];
  selected = nil;
}

- (void) validateEditing
{
}

- (BOOL) wantsSelection
{
  return NO;
}

- (NSWindow*) window
{
  NSLog(@"Ack - GormMatrix - window");
  return nil;
}


@end



