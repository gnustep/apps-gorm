/* GormWindowEditor.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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
#include "GormViewWithContentViewEditor.h"
#include <math.h>
#define _EO ((NSWindow *)_editedObject)
#include "GormInternalViewEditor.h"

@implementation NSWindow (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormWindowEditor";
}

/*
 * Method to return the image that should be used to display windows within
 * the matrix containing the objects in a document.
 */
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormWindow"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}

@end

/*
 *	Default implementations of methods used for updating a view by
 *	direct action through an editor.
 */
@implementation NSView (ViewAdditions)

- (BOOL) acceptsColor: (NSColor*)color atPoint: (NSPoint)point
{
  return NO;	/* Can the view accept a color drag-and-drop?	*/
}

- (BOOL) allowsAltDragging
{
  return NO;	/* Can the view be dragged into a matrix?	*/
}

- (void) depositColor: (NSColor*)color atPoint: (NSPoint)point
{
  					/* Handle color drop in view.	*/
}

- (NSSize) maximumSizeFromKnobPosition: (IBKnobPosition)knobPosition
{
  NSView	*s = [self superview];
  NSRect	r = (s != nil) ? [s bounds] : [self bounds];

  return r.size;			/* maximum resize permitted	*/
}

- (NSSize) minimumSizeFromKnobPosition: (IBKnobPosition)position
{
  return NSMakeSize(5, 5);		/* Minimum resize permitted	*/
}

- (void) placeView: (NSRect)newFrame
{
  [self setFrame: newFrame];		/* View changed by editor.	*/
}

@end



@interface GormWindowEditor : GormViewWithContentViewEditor
{
  NSWindow		*edited;
  NSView                *edit_view;
  NSMutableArray	*subeditors;
  BOOL			isLinkSource;
  NSPasteboard		*dragPb;
  NSString		*dragType;
}
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) changeFont: (id) sender;
- (void) close;
- (void) closeSubeditors;
//  - (void) copySelection;
- (void) deactivate;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) makeSelectionVisible: (BOOL)flag;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (void) resetObject: (id)anObject;
//  - (void) selectObjects: (NSArray*)objects;
//  - (void) validateEditing;
//  - (BOOL) wantsSelection;
//  - (NSWindow*) window;
@end

@implementation	GormWindowEditor

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  NSDebugLog(@"********* TELL pyr *********** acceptsFirstMouse");
  return YES;
}

- (BOOL) acceptsFirstResponder
{
  NSDebugLog(@"********* TELL pyr *********** acceptsFirstResponder");
  return YES;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Argh - encoding window editor"];
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  /*
   * A window editor can accept views pasted in to the window.
   */
  return [types containsObject: IBViewPboardType];
}

- (BOOL) activate
{
  if (activated == NO)
    {
      NSView *contentView = [_EO contentView];
      contentViewEditor = (GormInternalViewEditor *)[document editorForObject: contentView
							      inEditor: self 
							      create: YES];
      [(NSWindow *)_editedObject setInitialFirstResponder: self];
      [self setOpened: YES];
      activated = YES;
      return YES;
    }

  return NO;
}

- (void) changeFont: (id)sender
{
  NSDebugLog(@"********* TELL pyr *********** changeFont");
}

- (void) close
{
  NSAssert(closed == NO, NSInternalInconsistencyException);
  closed = YES;
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [self makeSelectionVisible: NO];
  if ([(id<IB>)NSApp selectionOwner] == self)
    {
      [document resignSelectionForEditor: self];
    }

  [self closeSubeditors];

  [self deactivate];

  [document editor: self didCloseForObject: edited];
}

- (void) closeSubeditors
{
  while ([subeditors count] > 0)
    {
      id<IBEditors>	sub = [subeditors lastObject];

      [sub close];
      [subeditors removeObjectIdenticalTo: sub];
    }
}

- (void) copySelection
{
  NSDebugLog(@"********* TELL pyr *********** copySelection");
}

- (void) deactivate
{
  if (activated == YES)
    {
      [contentViewEditor deactivate];
      activated = NO;
    }
  return;
}

- (void) dealloc
{
  if (closed == NO)
    {
      [self close];
    }
  RELEASE(edited);
  RELEASE(selection);
  RELEASE(subeditors);
  RELEASE(document);
  [super dealloc];
}

- (void) deleteSelection
{
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
  NSDebugLog(@"********* TELL pyr *********** draggedImage");
  /*
   * FIXME - handle this.
   * Notification that a drag failed/succeeded.
   */
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  NSDebugLog(@"********* TELL pyr *********** draggingSourceOperationMaskForLocal");
  return NSDragOperationNone;
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  return NSDragOperationNone;
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender
{
  return NSDragOperationNone;
}

- (void) drawSelection
{
  NSDebugLog(@"********* TELL pyr *********** drawSelection");
}

- (id<IBDocuments>) document
{
  return document;
}

- (id) initWithObject: (id)anObject 
	   inDocument: (id<IBDocuments>)aDocument
{
  _displaySelection = YES;
  _editedObject = (NSView*)anObject;
  edited = anObject;

  if ((self = [super initWithFrame: NSZeroRect]) == nil)
    return nil;

   document = aDocument;
 
  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    GormLinkPboardType, IBViewPboardType, nil]];

  selection = [NSMutableArray new];
  subeditors = [NSMutableArray new];

  [(NSWindow *)_editedObject setInitialFirstResponder: self];
  
  activated = NO;
  closed = NO;

  [self activate];
  
  return self;
}

- (void) makeSelectionVisible: (BOOL)flag
{
  if (flag == NO)
    {
      if ([selection count] > 0)
	{
	  NSEnumerator	*enumerator = [selection objectEnumerator];
	  NSView	*view;

	  [[self window] disableFlushWindow];
	  while ((view = [enumerator nextObject]) != nil)
	    {
	      NSRect	rect = GormExtBoundsForRect([view frame]);

	      [edit_view displayRect: rect];
	    }
	  [[self window] enableFlushWindow];
	  [[self window] flushWindowIfNeeded];
	}
    }
  else
    {
      [self drawSelection];
      [[self window] flushWindow];
    }
}

- (id<IBEditors>) openSubeditorForObject: (id)anObject
{
  NSDebugLog(@"********* TELL pyr *********** openSubeditorForObject");
  return nil;
}

- (void) orderFront
{
  [edited orderFront: self];
}

- (void) pasteInSelection
{
  NSDebugLog(@"********* TELL pyr *********** pasteInSelection");
//    [self pasteInView: edit_view];
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSDebugLog(@"********* TELL pyr *********** performDragOperation");
  return NO;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  return NO;
}

- (void) resetObject: (id)anObject
{
  [[self window] makeKeyAndOrderFront: self];
}

- (id) selectAllItems: (id)sender
{
  NSDebugLog(@"********* TELL pyr *********** selectAllItems");
  return nil;
}

- (unsigned) selectionCount
{
  NSDebugLog(@"********* TELL pyr *********** selectionCount");
  return  0;
//    return [selection count];
}

- (void) validateEditing
{
  NSDebugLog(@"********* TELL pyr *********** validateEditing");
}

- (void)windowDidBecomeMain: (id) aNotification
{
  NSDebugLog(@"windowDidBecomeMain %@", selection);
  if ([NSApp isConnecting] == NO)
    {
      [document setSelectionFromEditor: self];
      NSDebugLog(@"windowDidBecomeMain %@", selection);
      [self makeSelectionVisible: YES];
    }
}

- (void)windowDidResignMain: (id) aNotification
{
  NSDebugLog(@"windowDidResignMain");
  // [document setSelectionFromEditor: self];
  [self makeSelectionVisible: NO];
}

@end
