/* GormViewWithContentViewEditor.m
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

#import <AppKit/AppKit.h>

#include "GormPrivate.h"

#import "GormViewWithContentViewEditor.h"

#import "GormPlacementInfo.h"

#import "GormSplitViewEditor.h"


@interface GormViewEditor (Private)
- (NSRect) _displayMovingFrameWithHint: (NSRect) frame
		      andPlacementInfo: (GormPlacementInfo *)gpi;
@end



@implementation GormViewWithContentViewEditor

- (id) initWithObject: (id) anObject
  	   inDocument: (id<IBDocuments>)aDocument
{
  _displaySelection = YES;
  self = [super initWithObject: anObject
		inDocument: aDocument];
  return self;
}


- (void) handleMouseOnKnob: (IBKnobPosition) knob
		    ofView: (GormViewEditor *) view
		 withEvent: (NSEvent *) theEvent
{
  NSPoint	mouseDownPoint = [[view superview]
				   convertPoint: [theEvent locationInWindow]
				   fromView: nil];
  NSDate	*future = [NSDate distantFuture];
  BOOL		acceptsMouseMoved;
  unsigned	eventMask;
  NSEvent	*e;
  NSEventType	eType;
  NSRect	r = [view frame];
  NSPoint	maxMouse;
  NSPoint	minMouse;
  NSRect	firstRect = [view frame];
  NSRect	lastRect = [view frame];
//    NSRect        constrainRect = [view frame];
  NSPoint	lastPoint = mouseDownPoint;
  NSPoint	point = mouseDownPoint;
  NSView        *superview;
  GormPlacementInfo *gpi;

  eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask
    | NSMouseMovedMask | NSPeriodicMask;
  
  // Save window state info.
  acceptsMouseMoved = [[self window] acceptsMouseMovedEvents];
  [[self window] setAcceptsMouseMovedEvents: YES];

  superview = [view superview];
  [superview lockFocus];

  _displaySelection = NO;

  /*
   * Get size limits for resizing or moving and calculate maximum
   * and minimum mouse positions that won't cause us to exceed
   * those limits.
   */
  {
    NSSize	max = [view maximumSizeFromKnobPosition: knob];
    NSSize	min = [view minimumSizeFromKnobPosition: knob];
	  
    r = [superview frame];
      
    minMouse = NSMakePoint(NSMinX(r), NSMinY(r));
    maxMouse = NSMakePoint(NSMaxX(r), NSMaxY(r));
    r = [view frame];
    switch (knob)
      {
      case IBBottomLeftKnobPosition:
	maxMouse.x = NSMaxX(r) - min.width;
	minMouse.x = NSMaxX(r) - max.width;
	maxMouse.y = NSMaxY(r) - min.height;
	minMouse.y = NSMaxY(r) - max.height;
	break;
	      
      case IBMiddleLeftKnobPosition:
	maxMouse.x = NSMaxX(r) - min.width;
	minMouse.x = NSMaxX(r) - max.width;
	break;
	      
      case IBTopLeftKnobPosition:
	maxMouse.x = NSMaxX(r) - min.width;
	minMouse.x = NSMaxX(r) - max.width;
	maxMouse.y = NSMinY(r) + max.height;
	minMouse.y = NSMinY(r) + min.height;
	break;
	      
      case IBTopMiddleKnobPosition:
	maxMouse.y = NSMinY(r) + max.height;
	minMouse.y = NSMinY(r) + min.height;
	break;
	      
      case IBTopRightKnobPosition:
	maxMouse.x = NSMinX(r) + max.width;
	minMouse.x = NSMinX(r) + min.width;
	maxMouse.y = NSMinY(r) + max.height;
	minMouse.y = NSMinY(r) + min.height;
	break;
	      
      case IBMiddleRightKnobPosition:
	maxMouse.x = NSMinX(r) + max.width;
	minMouse.x = NSMinX(r) + min.width;
	break;
	      
      case IBBottomRightKnobPosition:
	maxMouse.x = NSMinX(r) + max.width;
	minMouse.x = NSMinX(r) + min.width;
	maxMouse.y = NSMaxY(r) - min.height;
	minMouse.y = NSMaxY(r) - max.height;
	break;
	      
      case IBBottomMiddleKnobPosition:
	maxMouse.y = NSMaxY(r) - min.height;
	minMouse.y = NSMaxY(r) - max.height;
	break;

      case IBNoneKnobPosition:
	break;	/* NOT REACHED */
      }
  }



  /* Set the arrows cursor in case it might be something else */
  [[NSCursor arrowCursor] push];

  /*
   * Track mouse movements until left mouse up.
   * While we keep track of all mouse movements, we only act on a
   * movement when a periodic event arives (every 20th of a second)
   * in order to avoid excessive amounts of drawing.
   */
  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.05];
  e = [NSApp nextEventMatchingMask: eventMask
	     untilDate: future
	     inMode: NSEventTrackingRunLoopMode
	     dequeue: YES];
  eType = [e type];

  if ([view respondsToSelector: @selector(initializeResizingInFrame:withKnob:)])
    {
      gpi = [(id)view initializeResizingInFrame: superview
		  withKnob: knob];
    }
  else
    {
      gpi = nil;
    }

  while (eType != NSLeftMouseUp)
    {
      if (eType != NSPeriodic)
	{
	  point = [superview convertPoint: [e locationInWindow]
			     fromView: nil];
	  /*
	  if (edit_view != self)
	    point = _constrainPointToBounds(point, [edit_view bounds]);
	  */
	}
      else if (NSEqualPoints(point, lastPoint) == NO)
	{
	  [[self window] disableFlushWindow];

	  {
	    float	xDiff;
	    float	yDiff;

	    if (point.x < minMouse.x)
	      point.x = minMouse.x;
	    if (point.y < minMouse.y)
	      point.y = minMouse.y;
	    if (point.x > maxMouse.x)
	      point.x = maxMouse.x;
	    if (point.y > maxMouse.y)
	      point.y = maxMouse.y;

	    xDiff = point.x - lastPoint.x;
	    yDiff = point.y - lastPoint.y;
	    lastPoint = point;

	    {
	      r = GormExtBoundsForRect(r/*constrainRect*/);
	      r.origin.x--;
	      r.origin.y--;
	      r.size.width += 2;
	      r.size.height += 2;
	      //	      [superview displayRect: r];
	      r = lastRect;
	      switch (knob)
		{
		case IBBottomLeftKnobPosition:
		  r.origin.x += xDiff;
		  r.origin.y += yDiff;
		  r.size.width -= xDiff;
		  r.size.height -= yDiff;
		  break;
			    
		case IBMiddleLeftKnobPosition:
		  r.origin.x += xDiff;
		  r.size.width -= xDiff;
		  break;

		case IBTopLeftKnobPosition:
		  r.origin.x += xDiff;
		  r.size.width -= xDiff;
		  r.size.height += yDiff;
		  break;
			    
		case IBTopMiddleKnobPosition:
		  r.size.height += yDiff;
		  break;

		case IBTopRightKnobPosition:
		  r.size.width += xDiff;
		  r.size.height += yDiff;
		  break;

		case IBMiddleRightKnobPosition:
		  r.size.width += xDiff;
		  break;

		case IBBottomRightKnobPosition:
		  r.origin.y += yDiff;
		  r.size.width += xDiff;
		  r.size.height -= yDiff;
		  break;

		case IBBottomMiddleKnobPosition:
		  r.origin.y += yDiff;
		  r.size.height -= yDiff;
		  break;

		case IBNoneKnobPosition:
		  break;	/* NOT REACHED */
		}

	      lastRect = r;

	      if ([view respondsToSelector: 
			  @selector(updateResizingWithFrame:andEvent:andPlacementInfo:)])
		{
		  [view updateResizingWithFrame: r
			andEvent: theEvent
			andPlacementInfo: gpi];
		}

	    }
	    /*
	     * Flush any drawing performed for this event.
	     */
	    [[self window] enableFlushWindow];
	    [[self window] flushWindow];
	  }
	}

      e = [NSApp nextEventMatchingMask: eventMask
		 untilDate: future
		 inMode: NSEventTrackingRunLoopMode
		 dequeue: YES];
      eType = [e type];
    }
  
  [NSEvent stopPeriodicEvents];
  [NSCursor pop];
  /* Typically after a view has been dragged in a window, NSWindow
	 sends a spurious moustEntered event. Sending the mouseUp
	 event back to the NSWindow resets the NSWindow's idea of the
	 last mouse point so it doesn't think that the mouse has
	 entered the view (since it was always there, it's just that
	 the view moved).  */
  [[self window] postEvent: e atStart: NO];

  {
    NSRect	redrawRect;

    /*
     * This was a subview resize, so we must clean up by removing
     * the highlighted knob and the wireframe around the view.
     */

    [view updateResizingWithFrame: r
	  andEvent: theEvent
	  andPlacementInfo: gpi];
    
    [view validateFrame: r
	  withEvent: theEvent
	  andPlacementInfo: gpi];

    r = GormExtBoundsForRect(lastRect);
    r.origin.x--;
    r.origin.y--;
    r.size.width += 2;
    r.size.height += 2;
    /*
     * If this was a simple resize, we must redraw the union of
     * the original frame, and the final frame, and the area
     * where we were drawing the wireframe and handles.
     */
    redrawRect = NSUnionRect(r, redrawRect);
    redrawRect = NSUnionRect(firstRect, redrawRect);
    //    [superview displayRect: redrawRect];
    //    [self makeSelectionVisible: YES];
  }

  
  if (NSEqualPoints(point, mouseDownPoint) == NO)
    {
      /*
       * A subview was moved or resized, so we must mark the
       * doucment as edited.
	   */
      [document touch];
    }

  [superview unlockFocus];
  _displaySelection = YES;
  
  [self setNeedsDisplay: YES];
  /*
   * Restore state to what it was on entry.
   */
  [[self window] setAcceptsMouseMovedEvents: acceptsMouseMoved];

}

- (void) handleMouseOnView: (GormViewEditor *) view
		 withEvent: (NSEvent *) theEvent
{
  NSPoint	mouseDownPoint = [[view superview]
				   convertPoint: [theEvent locationInWindow]
				   fromView: nil];
  NSDate	*future = [NSDate distantFuture];
  NSView	*subview;
  BOOL		acceptsMouseMoved;
  BOOL		dragStarted = NO;
  unsigned	eventMask;
  NSEvent	*e;
  NSEventType	eType;
  NSRect	r;
  NSPoint	maxMouse;
  NSPoint	minMouse;
  NSPoint	lastPoint = mouseDownPoint;
  NSPoint	point = mouseDownPoint;
  NSView        *superview;
  NSEnumerator		*enumerator;
  NSRect        oldMovingFrame;
  NSRect        suggestedFrame;
  GormPlacementInfo *gpi;
  
//    NSLog(@"hMOV %@", self);

  eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask
    | NSMouseMovedMask | NSPeriodicMask;
  
  // Save window state info.
  acceptsMouseMoved = [[self window] acceptsMouseMovedEvents];
  [[self window] setAcceptsMouseMovedEvents: YES];

  if (view == nil)
    {
      return;
    }

  if ([theEvent modifierFlags] & NSShiftKeyMask)
    {
      if ([selection containsObject: view])
	{
	  NSMutableArray *newSelection = [selection mutableCopy];
	  [newSelection removeObjectIdenticalTo: view];
	  [self selectObjects: newSelection];
	  RELEASE(newSelection);
	  return;
	}
      else
	{
	  NSArray *newSelection;
	  newSelection = [selection arrayByAddingObject: view];
	  [self selectObjects: newSelection];
	}
    }
  else
    {
      [self selectObjects: [NSArray arrayWithObject: view]];
    }

  superview = [view superview];
  [superview lockFocus];
  
  {
    NSRect	vf = [view frame];
    NSRect	sf = [superview bounds];
    NSPoint	tr = NSMakePoint(NSMaxX(vf), NSMaxY(vf));
    NSPoint	bl = NSMakePoint(NSMinX(vf), NSMinY(vf));
    
    enumerator = [selection objectEnumerator];
    while ((subview = [enumerator nextObject]) != nil)
      {
	if (subview != view)
	  {
	    float	tmp;
	    
	    vf = [subview frame];
	    tmp = NSMaxX(vf);
	    if (tmp > tr.x)
	      tr.x = tmp;
	    tmp = NSMaxY(vf);
	    if (tmp > tr.y)
	      tr.y = tmp;
	    tmp = NSMinX(vf);
	    if (tmp < bl.x)
	      bl.x = tmp;
	    tmp = NSMinY(vf);
	    if (tmp < bl.y)
	      bl.y = tmp;
	  }
      }
    minMouse.x = point.x - bl.x;
    minMouse.y = point.y - bl.y;
    maxMouse.x = NSMaxX(sf) - tr.x + point.x;
    maxMouse.y = NSMaxY(sf) - tr.y + point.y;
  }

  if ([selection count] == 1)
    {
      oldMovingFrame = [[selection objectAtIndex: 0] frame];
      gpi = [[selection objectAtIndex: 0] initializeResizingInFrame: 
					     [self superview]
					   withKnob: IBNoneKnobPosition];
      suggestedFrame = oldMovingFrame;
    }
  
  /* Set the arrows cursor in case it might be something else */
  [[NSCursor arrowCursor] push];

  /*
   * Track mouse movements until left mouse up.
   * While we keep track of all mouse movements, we only act on a
   * movement when a periodic event arives (every 20th of a second)
   * in order to avoid excessive amounts of drawing.
   */
  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.05];
  e = [NSApp nextEventMatchingMask: eventMask
	     untilDate: future
	     inMode: NSEventTrackingRunLoopMode
	     dequeue: YES];

  eType = [e type];
  while (eType != NSLeftMouseUp)
    {
      if (eType != NSPeriodic)
	{
	  point = [superview convertPoint: [e locationInWindow]
			     fromView: nil];
	  /*
	    point = _constrainPointToBounds(point, [superview bounds]);
	  */
	}
      else if (NSEqualPoints(point, lastPoint) == NO)
	{
	  [[self window] disableFlushWindow];

	  {
	    float	xDiff;
	    float	yDiff;

	    if (point.x < minMouse.x)
	      point.x = minMouse.x;
	    if (point.y < minMouse.y)
	      point.y = minMouse.y;
	    if (point.x > maxMouse.x)
	      point.x = maxMouse.x;
	    if (point.y > maxMouse.y)
	      point.y = maxMouse.y;

	    xDiff = point.x - lastPoint.x;
	    yDiff = point.y - lastPoint.y;
	    lastPoint = point;

	    if (dragStarted == NO)
	      {
		/*
		 * Remove selection knobs before moving selection.
		 */
		dragStarted = YES;
		_displaySelection = NO;
		[self setNeedsDisplay: YES];
	      }

  	    if ([selection count] == 1)
  	      {
		[[selection objectAtIndex: 0] 
		  setFrameOrigin:
		    NSMakePoint(NSMaxX([self bounds]),
				NSMaxY([self bounds]))];
		[superview display];

		r = oldMovingFrame;
		r.origin.x += xDiff;
		r.origin.y += yDiff;
		r.origin.x = (int) r.origin.x;
		r.origin.y = (int) r.origin.y;
		r.size.width = (int) r.size.width;
		r.size.height = (int) r.size.height;
		oldMovingFrame = r;
		suggestedFrame = [[selection objectAtIndex: 0]
				   _displayMovingFrameWithHint: r
				   andPlacementInfo: gpi];
		[[selection objectAtIndex: 0] setFrame:
						suggestedFrame];
		[[selection objectAtIndex: 0] setNeedsDisplay: YES];
		
  	      }
  	    else
	      {
		enumerator = [selection objectEnumerator];
		
		while ((subview = [enumerator nextObject]) != nil)
		  {
		    NSRect	oldFrame = [subview frame];
		    
		    r = oldFrame;
		    r.origin.x += xDiff;
		    r.origin.y += yDiff;
		    r.origin.x = (int) r.origin.x;
		    r.origin.y = (int) r.origin.y;
		    r.size.width = (int) r.size.width;
		    r.size.height = (int) r.size.height;
		    [subview setFrame: r];
		    [superview setNeedsDisplayInRect: oldFrame];
		    [subview setNeedsDisplay: YES];
		  }
	      }

	    /*
	     * Flush any drawing performed for this event.
	     */
	    [[self window] displayIfNeeded];
	    [[self window] enableFlushWindow];
	    [[self window] flushWindow];
	  }
	}
      e = [NSApp nextEventMatchingMask: eventMask
		 untilDate: future
		 inMode: NSEventTrackingRunLoopMode
		 dequeue: YES];
      eType = [e type];
    }

  _displaySelection = YES;

  if ([selection count] == 1)
    [[selection objectAtIndex: 0] setFrame: suggestedFrame];
  [self setNeedsDisplay: YES];
  [NSEvent stopPeriodicEvents];
  [NSCursor pop];
  /* Typically after a view has been dragged in a window, NSWindow
     sends a spurious moustEntered event. Sending the mouseUp
     event back to the NSWindow resets the NSWindow's idea of the
     last mouse point so it doesn't think that the mouse has
     entered the view (since it was always there, it's just that
     the view moved).  */
  [[self window] postEvent: e atStart: NO];
  
  
  if (NSEqualPoints(point, mouseDownPoint) == NO)
    {
      /*
       * A subview was moved or resized, so we must mark the
       * doucment as edited.
       */
      [document touch];
    }

  [superview unlockFocus];
  /*
   * Restore state to what it was on entry.
   */
  [[self window] setAcceptsMouseMovedEvents: acceptsMouseMoved];
 
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  if ([super acceptsTypeFromArray: types])
    {
      return YES;
    }
  else
    {
      return [types containsObject: IBViewPboardType];
    }
}

- (void) postDrawForView: (GormViewEditor *) viewEditor
{
  if (_displaySelection == NO)
    {
      return;
    }
  if (((id)openedSubeditor == (id)viewEditor) 
      && (openedSubeditor != nil)
      && ![openedSubeditor isKindOfClass: [GormInternalViewEditor class]])
    {
      GormDrawOpenKnobsForRect([viewEditor bounds]);
      GormShowFastKnobFills();
    }
  else if ([selection containsObject: viewEditor])
    {
      GormDrawKnobsForRect([viewEditor bounds]);
      GormShowFastKnobFills();
    }
}

- (void) postDraw: (NSRect) rect
{
  [super postDraw: rect];

  if (openedSubeditor 
      && ![openedSubeditor isKindOfClass: [GormInternalViewEditor class]])
    {
      GormDrawOpenKnobsForRect(
			       [self convertRect: [openedSubeditor bounds]
				     fromView: openedSubeditor]);
      GormShowFastKnobFills();
    }
  else if (_displaySelection)
    {
      int i;
      int count = [selection count];

      for ( i = 0; i < count ; i++ )
	{
	  GormDrawKnobsForRect([self convertRect:
				       [[selection objectAtIndex: i] bounds]
				     fromView: [selection objectAtIndex: i]]);
	  GormShowFastKnobFills();
	}
    }

}





#undef MAX
#undef MIN

#define MAX(A,B) ((A)>(B)?(A):(B))
#define MIN(A,B) ((A)<(B)?(A):(B))

- (void) groupSelectionInSplitView
{
  NSEnumerator *enumerator;
  GormViewEditor *subview;
  NSSplitView *splitView;
  NSRect rect = NSZeroRect;
  GormViewEditor *editor;
  NSView *superview;

  if ([selection count] < 2)
    {
      return;
    }
  
  enumerator = [selection objectEnumerator];
  
  while ((subview = [enumerator nextObject]) != nil)
    {
      superview = [subview superview];
      rect = NSUnionRect(rect, [subview frame]);
      [subview deactivate];
    }

  splitView = [[NSSplitView alloc] initWithFrame: rect];

  
  [document attachObject: splitView 
	    toParent: _editedObject];

  [superview addSubview: splitView];


  enumerator = [selection objectEnumerator];
  
  editor = [document editorForObject: splitView
		     inEditor: self
		     create: YES];

  while ((subview = [enumerator nextObject]) != nil)
    {
      id eO = [subview editedObject];
      [splitView addSubview: [subview editedObject]];
      [document attachObject: [subview editedObject]
		toParent: splitView];
      [subview close];
      [document editorForObject: eO
	  inEditor: editor
	  create: YES];
    }
  
  [self selectObjects: [NSArray arrayWithObject: editor]];
}

- (void) groupSelectionInBox
{
  NSEnumerator *enumerator;
  GormViewEditor *subview;
  NSBox *box;
  NSRect rect = NSZeroRect;
  GormViewEditor *editor;
  NSView *superview;

  if ([selection count] < 1)
    {
      return;
    }
  
  enumerator = [selection objectEnumerator];
  
  while ((subview = [enumerator nextObject]) != nil)
    {
      superview = [subview superview];
      rect = NSUnionRect(rect, [subview frame]);
      [subview deactivate];
    }

  box = [[NSBox alloc] initWithFrame: NSZeroRect];
  [box setFrameFromContentFrame: rect];
  
  [document attachObject: box
	    toParent: _editedObject];

  [superview addSubview: box];


  enumerator = [selection objectEnumerator];

  while ((subview = [enumerator nextObject]) != nil)
    {
      NSPoint frameOrigin;
      [box addSubview: [subview editedObject]];
      frameOrigin = [[subview editedObject] frame].origin;
      frameOrigin.x -= rect.origin.x;
      frameOrigin.y -= rect.origin.y;
      [[subview editedObject] setFrameOrigin: frameOrigin];
      [subview close];
    }

  editor = [document editorForObject: box
		     inEditor: self
		     create: YES];
  
  [self selectObjects: [NSArray arrayWithObject: editor]];
}


@class GormBoxEditor;
@class GormSplitViewEditor;

- (void) ungroup
{
  NSView *toUngroup;

  if ([selection count] != 1)
    return;
  
  NSLog(@"ungroup called");

  toUngroup = [selection objectAtIndex: 0];


  if ([toUngroup isKindOfClass: [GormBoxEditor class]]
      || [toUngroup isKindOfClass: [GormSplitViewEditor class]])
    {
      id contentView = toUngroup;

      NSMutableArray *newSelection = [NSMutableArray array];
      NSArray *views;
      int i;
      views = [contentView destroyAndListSubviews];
      for (i = 0; i < [views count]; i++)
	{
	  [_editedObject addSubview: [views objectAtIndex: i]];
	  [newSelection addObject:
			  [document editorForObject: [views objectAtIndex: i]
				    inEditor: self
				    create: YES]];
	}
      [self selectObjects: newSelection];
      
    }

}

- (void) pasteInView: (NSView *)view
{
  NSPasteboard	 *pb = [NSPasteboard generalPasteboard];
  NSMutableArray *array = [NSMutableArray array];
  NSArray	 *views;
  NSEnumerator	 *enumerator;
  NSView         *sub;
  /*
  NSView	 *subs = [view subviews];
  int            i;
  int            count;
  BOOL           alreadyThere = YES;
  */

  /*
   * Ask the document to get the copied views from the pasteboard and add
   * them to it's collection of known objects.
   */
  views = [document pasteType: IBViewPboardType
	       fromPasteboard: pb
		       parent: _editedObject];
  /*
   * Now make all the views subviews of ourself.
   */
  enumerator = [views objectEnumerator];
  while ((sub = [enumerator nextObject]) != nil)
    {
      if ([sub isKindOfClass: [NSView class]] == YES)
	{
	  /*
	  for( i = 0; i < count; i++ )
	    {
	      if (NSEqualRects([sub frame], 
			       [[subs objectAtIndex: i] frame]))
		break;
	    }
	  if (i >= count)
	    alreadyThere = NO;
	  */
	  [view addSubview: sub];
	  [array addObject:
		   [document editorForObject: sub 
			     inEditor: self 
			     create: YES]];
	}
    }
  //  [self makeSelectionVisible: NO];
  [self selectObjects: array];
  //  [self makeSelectionVisible: YES];
}

@end
