/* GormViewWithSubviewsEditor.m
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

#include <AppKit/AppKit.h>

#include <GormCore/GormPrivate.h>
#include <GormCore/GormViewWithSubviewsEditor.h>
#include <GormCore/GormFontViewController.h>

@class GormEditorToParent;

/*
@implementation NSView (IBObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormViewWithSubviewsEditor";
}
@end
*/

@implementation GormViewWithSubviewsEditor

- (id) initWithObject: (id)anObject 
	   inDocument: (id<IBDocuments>)aDocument
{
  opened = NO;
  openedSubeditor = nil;

  if ((self = [super initWithObject: anObject
		     inDocument: aDocument]) == nil)
    return nil;

  selection = [[NSMutableArray alloc] initWithCapacity: 5];
  
  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    IBViewPboardType, GormLinkPboardType, IBFormatterPboardType, nil]];
  
  return self;
}

- (void) close
{
  if (closed == NO)
    {
      [self deactivate];
      
      [self closeSubeditors];
      [document editor: self didCloseForObject: _editedObject];
      closed = YES;
    }
  else
    {
      NSDebugLog(@"%@ close but already closed", self);
    }
}

- (void) deactivateSubeditors
{
  NSArray *subeditorConnections = 
    [NSArray arrayWithArray: [document connectorsForDestination: self
				       ofClass: [GormEditorToParent class]]];
  
  int count = [subeditorConnections count];
  int i;
  
  for ( i = 0; i < count; i ++ )
    {
      [[[subeditorConnections objectAtIndex: i] source] deactivate];
    }
}

- (void) closeSubeditors
{
  NSArray *subeditorConnections = 
    [NSArray arrayWithArray: [document connectorsForDestination: self
				       ofClass: [GormEditorToParent class]]];

  int count = [subeditorConnections count];
  int i;

  for ( i = 0; i < count; i ++ )
    {
      [[[subeditorConnections objectAtIndex: i] source] close];
    }
}

- (BOOL) canBeOpened
{
  return YES;
}

- (BOOL) isOpened
{
  return opened;
}


- (void) setOpened: (BOOL) value
{
  opened = value;

  if (value == YES)
    {
      [self silentlyResetSelection];
      // [document setSelectionFromEditor: self];      
    }
  else
    {
      if (openedSubeditor != nil)
	{
	  [self makeSubeditorResign];
	  [self silentlyResetSelection];
	}
      else
	{
	  [self silentlyResetSelection];
	}
      [self setNeedsDisplay: YES];
    }
}

/*
 *  
 */
- (void) openParentEditor
{
  if ([parent respondsToSelector: @selector(setOpenedSubeditor:)])
    {
      [parent setOpenedSubeditor: self];
    }
}

- (void) setOpenedSubeditor: (GormViewWithSubviewsEditor *) newEditor
{
  [self silentlyResetSelection];

  if (opened == NO)
    {
      [self openParentEditor];
    }

  opened = YES;

  if (newEditor != openedSubeditor)
    {
      [self makeSubeditorResign];
    }
  
  openedSubeditor = newEditor;

  [self setNeedsDisplay: YES];
}

/*
 *  take the selection from the subeditors
 */
- (void) makeSubeditorResign
{
  if (openedSubeditor != nil)
    {
      [openedSubeditor makeSubeditorResign];
      [openedSubeditor setOpened: NO];
      openedSubeditor = nil;
    }
}


- (void) makeSelectionVisible: (BOOL) value
{
}

- (void) changeFont: (id)sender
{
  NSEnumerator *enumerator = [[self selection] objectEnumerator];
  id anObject;
  NSFont *newFont;

  while ((anObject = [enumerator nextObject]))
    {
      if ([anObject respondsToSelector: @selector(font)]
	  && [anObject respondsToSelector: @selector(setFont:)])
	{
	  newFont = [sender convertFont: [anObject font]];
	  newFont = [[GormFontViewController sharedGormFontViewController] 
	    convertFont: newFont];
	  [anObject setFont: newFont];
	}
    }

  return;
}

- (NSArray*) selection
{
  int i;
  int count = [selection count];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: count];
  
  if (count != 0)
    {
      for (i = 0; i < count; i++)
	{
	  if ([[selection objectAtIndex: i] 
		respondsToSelector: @selector(editedObject)])
	    [result addObject: [[selection objectAtIndex: i] editedObject]];
	  else
	    [result addObject: [selection objectAtIndex: i]];
	}
    }
  else
    {
      if ([self respondsToSelector: @selector(editedObject)])
	[result addObject: [self editedObject]];
      else
	[result addObject: self];
    }

  return result;
}

- (void) selectObjects: (NSArray *) objects
{
  int i;
  int count = [objects count];
  TEST_RELEASE(selection);
  
  selection = [[NSMutableArray alloc] initWithCapacity: [objects count]];

  for (i = 0; i < count; i++)
    {
      [selection addObject: [objects objectAtIndex: i]];
    }

  [self makeSubeditorResign];

  opened = YES;

  [self openParentEditor];

  [document setSelectionFromEditor: self];

  [self setNeedsDisplay: YES];
}

- (void) silentlyResetSelection
{
  TEST_RELEASE(selection);
  
  selection = [[NSMutableArray alloc] initWithCapacity: 5];
  
}

- (void) copySelection
{
  if ([selection count] > 0)
    {
      [document copyObjects: [self selection]
		       type: IBViewPboardType
	       toPasteboard: [NSPasteboard generalPasteboard]];
    }
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (void) drawSelection
{
  // doesn nothing.
}

- (unsigned) selectionCount
{
  return [selection count];
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSRect rect = [_editedObject bounds];
  NSPoint loc = [sender draggingLocation];
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  loc = [_editedObject convertPoint: loc fromView: nil];

  if ([types containsObject: GormLinkPboardType] == YES)
    {
      return [parent draggingEntered: sender];
    }

  if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
    {
      return NSDragOperationNone;
    }
  else
    {
      rect.origin.x += 3;
      rect.origin.y += 2;
      rect.size.width -= 5;
      rect.size.height -= 5;
      
      [_editedObject lockFocus];
      
      [[NSColor darkGrayColor] set];
      NSFrameRectWithWidth(rect, 2);
      
      [_editedObject unlockFocus];
      [[self window] flushWindow];
      return NSDragOperationCopy;
    }
}

- (void) draggingExited: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  NSRect         rect;

  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      [parent draggingExited: sender];
      return;
    }


  rect = [_editedObject bounds];
  rect.origin.x += 3;
  rect.origin.y += 2;
  rect.size.width -= 5;
  rect.size.height -= 5;
 
  rect.origin.x --;
  rect.size.width ++;
  rect.size.height ++;

  [[self window] disableFlushWindow];
  [self displayRect: 
	  [_editedObject convertRect: rect
			 toView: self]];
  [[self window] enableFlushWindow];
  [[self window] flushWindow];
}

- (unsigned int) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSPoint loc = [sender draggingLocation];
  NSRect rect = [_editedObject bounds];
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  loc = [_editedObject 
	  convertPoint: loc fromView: nil];

  if ([types containsObject: GormLinkPboardType] == YES)
    {
      return [parent draggingUpdated: sender];
    }

  rect.origin.x += 3;
  rect.origin.y += 2;
  rect.size.width -= 5;
  rect.size.height -= 5;

  if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
    {
      [[self window] disableFlushWindow];
      rect.origin.x --;
      rect.size.width ++;
      rect.size.height ++;
      [self displayRect: 
	      [_editedObject convertRect: rect
			     toView: self]];
      [[self window] enableFlushWindow];
      [[self window] flushWindow];
      return NSDragOperationNone;
    }
  else
    {
      [_editedObject lockFocus];
      
      [[NSColor darkGrayColor] set];
      NSFrameRectWithWidth(rect, 2);
      
      [_editedObject unlockFocus];
      [[self window] flushWindow];
      return NSDragOperationCopy;
    }
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  NSString		*dragType;
  NSArray *types;
  NSPasteboard		*dragPb;

  dragPb = [sender draggingPasteboard];

  types = [dragPb types];
  
  if ([types containsObject: IBViewPboardType] == YES)
    {
      dragType = IBViewPboardType;
    }
  else if ([types containsObject: GormLinkPboardType] == YES)
    {
      dragType = GormLinkPboardType;
      return [parent prepareForDragOperation: sender];
    }
  else
    {
      dragType = nil;
    }

  if (dragType == IBViewPboardType)
    {
      /*
       * We can accept views dropped anywhere.
       */
      NSPoint		loc = [sender draggingLocation];
      loc = [_editedObject  
	      convertPoint: loc fromView: nil];
      if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
	{
	  return NO;
	}
      
      return YES;
    }
  
  return NO;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSString		*dragType;
  NSPasteboard		*dragPb;
  NSArray *types;

  dragPb = [sender draggingPasteboard];

  types = [dragPb types];
  
  if ([types containsObject: IBViewPboardType] == YES)
    {
      dragType = IBViewPboardType;
    }
  else if ([types containsObject: GormLinkPboardType] == YES)
    {
      dragType = GormLinkPboardType;
    }
  else
    {
      dragType = nil;
    }

  if (dragType == IBViewPboardType)
    {
      NSPoint		loc = [sender draggingLocation];
      NSArray		*views;
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
       * Ask the document to get the dragged views from the pasteboard and add
       * them to it's collection of known objects.
       */
      views = [document pasteType: IBViewPboardType
		   fromPasteboard: dragPb
			   parent: _editedObject];
      /*
       * Now make all the views subviews of ourself, setting their origin to
       * be the point at which they were dropped (converted from window
       * coordinates to our own coordinates).
       */
      loc = [_editedObject convertPoint: loc fromView: nil];
      if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
	{
	  // Dropped outside our view frame
	  NSLog(@"Dropped outside current edit view");
	  dragType = nil;
	  return NO;
	}
      enumerator = [views objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  NSRect	rect = [sub frame];
	  
	  rect.origin = [_editedObject
			  convertPoint: [sender draggedImageLocation]
			  fromView: nil];
	  rect.origin.x = (int) rect.origin.x;
	  rect.origin.y = (int) rect.origin.y;
	  rect.size.width = (int) rect.size.width;
	  rect.size.height = (int) rect.size.height;
	  [sub setFrame: rect];

	  [_editedObject addSubview: sub];
	  
	  {
	    id editor;
	    editor = [document editorForObject: sub 
			       inEditor: self 
			       create: YES];
	    [self selectObjects: 
		    [NSArray arrayWithObject: editor]];
	  }
	}
    }

  return YES;
}

@end
