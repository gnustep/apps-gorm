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

#import "GormViewWithContentViewEditor.h"

#include <math.h>

#define _EO ((NSWindow *)_editedObject)

#import "GormInternalViewEditor.h"


//  static NSRect
//  NSRectFromPoints(NSPoint p0, NSPoint p1)
//  {
//    NSRect	r;

//    if (p0.x < p1.x)
//      {
//        r.origin.x = p0.x;
//        r.size.width = p1.x - p0.x;
//      }
//    else
//      {
//        r.origin.x = p1.x;
//        r.size.width = p0.x - p1.x;
//      }
//    if (p0.y < p1.y)
//      {
//        r.origin.y = p0.y;
//        r.size.height = p1.y - p0.y;
//      }
//    else
//      {
//        r.origin.y = p1.y;
//        r.size.height = p0.y - p1.y;
//      }
//    return r;
//  }

//  static NSPoint
//  _constrainPointToBounds(NSPoint point, NSRect bounds)
//  {
//    point.x = MAX(point.x, NSMinX(bounds));
//    point.x = MIN(point.x, NSMaxX(bounds));
//    point.y = MAX(point.y, NSMinY(bounds));
//    point.y = MIN(point.y, NSMaxY(bounds));
//    return point;
//  }

//  @class GSTableCornerView;

//  static NSView *bestKnownSuperview(NSView *aView, NSPoint loc)
//  {
//    NSView *best = aView;
//    NSView *view = aView;
//    NSLog(@"Convert %@", aView);
  
//    if ([view isKindOfClass:[NSTableHeaderView class]])
//      {
//        NSPoint p = [view convertPoint: loc
//  			 fromView: nil];
//        int columnNumber = [(NSTableHeaderView*) view columnAtPoint: p];

//        if (columnNumber == -1)
//  	return nil;

//        if ([(NSTableHeaderView*)view tableView] == nil)
//  	return nil;

//        return [[[(NSTableHeaderView*)view tableView] tableColumns] 
//  	       objectAtIndex: columnNumber];
//      }
//    else if ([view isKindOfClass:[GSTableCornerView class]])
//      {
//        if ([view enclosingScrollView] != nil)
//  	return [view enclosingScrollView];
//      }
//    else if ([view isKindOfClass:[NSScroller class]])
//      {
//        if ([view enclosingScrollView] != nil)
//  	{
//  	  if ([[view enclosingScrollView] documentView]
//  	      && ([[[view enclosingScrollView] documentView]
//  		    isKindOfClass: [NSTableView class]]
//  		  || [[[view enclosingScrollView] documentView]
//  		       isKindOfClass: [NSTextView class]])
//  	      )
//  	    return [view enclosingScrollView];
//  	}
//      }
  
//    while( view )
//      {
//        if([view isKindOfClass:[NSBrowser class]] 
//  	 || [view isKindOfClass:[NSTextView class]]
//  	 || [view isKindOfClass:[NSTableView class]])
//          {
//  	  best = view;
//  	  break;
//          }
//        else if([view isKindOfClass:[NSScrollView class]])
//          {
//  	  best = view;
//          }
      
//        view = [view superview];
//      }
  
//    if([best isKindOfClass:[NSScrollView class]])
//      {
//        view = [best contentView];
//        if([view isKindOfClass:[NSClipView class]])
//  	{
//  	  view = [view documentView];
	  
//  	  if([view isKindOfClass:[NSTextView class]] 
//  	     || [view isKindOfClass:[NSTableView class]])
//  	    {
//  	      return view;
//  	    }
//  	}
//      }
  
//    return best;
//  }

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
//- (NSWindow*) window;
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
//        NSLog(@"contentView %@", contentView);
      contentViewEditor = [document editorForObject: contentView
				    inEditor: self 
				    create: YES];
//        NSLog(@"contentViewEditor %@", contentViewEditor);
      [(NSWindow *)_editedObject setInitialFirstResponder: self];
      [self setOpened: YES];
      activated = YES;
      return YES;
    }

  return NO;
}

- (void) changeFont: (id)sender
{
  NSLog(@"********* TELL pyr *********** changeFont");
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
  NSLog(@"********* TELL pyr *********** copySelection");
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
  NSLog(@"********* TELL pyr *********** draggedImage");
  /*
   * FIXME - handle this.
   * Notification that a drag failed/succeeded.
   */
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  NSLog(@"********* TELL pyr *********** draggingSourceOperationMaskForLocal");
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
  NSLog(@"********* TELL pyr *********** drawSelection");
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
  NSLog(@"********* TELL pyr *********** openSubeditorForObject");
  return nil;
}

- (void) orderFront
{
  [edited orderFront: self];
}

- (void) pasteInSelection
{
  NSLog(@"********* TELL pyr *********** pasteInSelection");
//    [self pasteInView: edit_view];
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSLog(@"********* TELL pyr *********** performDragOperation");
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
  NSLog(@"********* TELL pyr *********** selectAllItems");
  return nil;
}

- (unsigned) selectionCount
{
  NSLog(@"********* TELL pyr *********** selectionCount");
  return  0;
//    return [selection count];
}

- (void) validateEditing
{
  NSLog(@"********* TELL pyr *********** validateEditing");
}

- (void)windowDidBecomeMain: (id) aNotification
{
  NSLog(@"windowDidBecomeMain %@", selection);
  if ([NSApp isConnecting] == NO)
    {
      [document setSelectionFromEditor: self];
      NSLog(@"windowDidBecomeMain %@", selection);
      [self makeSelectionVisible: YES];
    }
}

- (void)windowDidResignMain: (id) aNotification
{
  NSLog(@"windowDidResignMain");
  // [document setSelectionFromEditor: self];
  [self makeSelectionVisible: NO];
}

@end
