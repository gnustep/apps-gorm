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

static NSRect
NSRectFromPoints(NSPoint p0, NSPoint p1)
{
  NSRect	r;

  if (p0.x < p1.x)
    {
      r.origin.x = p0.x;
      r.size.width = p1.x - p0.x;
    }
  else
    {
      r.origin.x = p1.x;
      r.size.width = p0.x - p1.x;
    }
  if (p0.y < p1.y)
    {
      r.origin.y = p0.y;
      r.size.height = p1.y - p0.y;
    }
  else
    {
      r.origin.y = p1.y;
      r.size.height = p0.y - p1.y;
    }
  return r;
}

/*
 * Methods to return the images that should be used to display objects within
 * the matrix containing the objects in a document.
 */
@implementation NSMenu (GormObjectAdditions)
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormMenu"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end

@implementation NSWindow (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormWindowEditor";
}
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



@interface	GormWindowEditor : NSView <IBEditors>
{
  id<IBDocuments>	document;
  NSWindow		*edited;
  NSView		*original;
  NSMutableArray	*selection;
  NSMutableArray	*subeditors;
  BOOL			isLinkSource;
  BOOL			isClosed;
  NSPasteboard		*dragPb;
  NSString		*dragType;
}
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) close;
- (void) closeSubeditors;
- (void) copySelection;
- (void) deactivate;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (id) editedObject;
- (void) makeSelectionVisible: (BOOL)flag;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (void) resetObject: (id)anObject;
- (void) selectObjects: (NSArray*)objects;
- (void) validateEditing;
- (BOOL) wantsSelection;
- (NSWindow*) window;
@end

@implementation	GormWindowEditor

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Argh - encoding window editor"];
}

/*
 *	Intercepting events in the view and handling them
 */
- (NSView*) hitTest: (NSPoint)loc
{
  if ([(id<IB>)NSApp isTestingInterface] == YES)
    {
      return [super hitTest: loc];
    }
  else
    {
      /*
       * Stop the subviews receiving events - we grab them all.
       */
      if ([super hitTest: loc] != nil)
	{
	  return self;
	}
      return nil;
    }
}

- (void) mouseDown: (NSEvent*)theEvent
{
  if ([(id<IB>)NSApp isTestingInterface] == YES)
    {
      [super mouseDown: theEvent];
      return;
    }
  else
    {
      NSEnumerator	*enumerator;
      NSView		*view = nil;
      IBKnobPosition	knob = IBNoneKnobPosition;
      NSPoint		mouseDownPoint;
      NSMutableArray	*array;

      mouseDownPoint = [theEvent locationInWindow];

      /*
       * If we have any subviews selected, we need to check to see if the knob
       * of any subview has been hit, or if a subview itsself has been hit.
       */
      if ([selection count] != 0)
	{
	  enumerator = [selection objectEnumerator];
	  while ((view = [enumerator nextObject]) != nil)
	    {
	      knob = GormKnobHitInRect([view frame], mouseDownPoint);
	      if (knob != IBNoneKnobPosition)
		{
		  /*
		   * Clicked on the knob of a selected subview.
		   * If it's not the only selected view - make it so.
		   * We now expect to drag from this.
		   */
		  if ([selection count] != 1)
		    {
		      [self selectObjects: [NSArray arrayWithObject: view]];
		    }
		  [self makeSelectionVisible: NO];
		  [self lockFocus];
		  GormShowFrameWithKnob([view frame], knob);
		  [self unlockFocus];
		  [[self window] flushWindow];
		  break;
		}
	    }
	  if (view == nil)
	    {
	      enumerator = [selection objectEnumerator];
	      while ((view = [enumerator nextObject]) != nil)
		{
		  if (NSMouseInRect(mouseDownPoint, [view frame], NO) == YES)
		    {
		      /*
		       * Clicked inside a selected subview.
		       */
		      if ([theEvent modifierFlags] & NSShiftKeyMask)
			{
			  /*
			   * remove this view from the selection.
			   */
			  [self makeSelectionVisible: NO];
			  array = [NSMutableArray arrayWithArray: selection];
			  [array removeObjectIdenticalTo: view];
			  [self selectObjects: array];
			}
		      else
			{
			  [self makeSelectionVisible: YES];
			}
		      break;
		    }
		}
	    }
	}

      /*
       * If we haven't clicked in a selected subview - find out where we
       * actually did click.
       */
      if (view == nil)
	{
	  view = [super hitTest: mouseDownPoint];
	  if (view == self)
	    {
	      /*
	       * Clicked on an window background - empty the selection.
	       */
	      [self makeSelectionVisible: NO];
	      [self selectObjects: [NSArray array]];
	    }
	  else if (view != nil)
	    {
	      /*
	       * Clicked on an unselected subview.
	       */
	      if ([theEvent modifierFlags] & NSShiftKeyMask)
		{
		  if ([selection lastObject] == edited
		    || ([theEvent modifierFlags] & NSControlKeyMask))
		    {
		      /*
		       * Can't extend the selection - change it to the subview.
		       */
		      [self makeSelectionVisible: NO];
		      [self selectObjects: [NSArray arrayWithObject: view]];
		    }
		  else
		    {
		      /*
		       * extend the selection to include this subview.
		       */
		      array = [NSMutableArray arrayWithArray: selection];
		      [array addObject: view];
		      [self selectObjects: array];
		    }
		}
	      else
		{
		  /*
		   * Select the new view (clear the old selection markings)
		   */
		  [self makeSelectionVisible: NO];
		  [self selectObjects: [NSArray arrayWithObject: view]];
		}
	    }
	}
      else if ([selection indexOfObjectIdenticalTo: view] == NSNotFound)
	{
	  /*
	   * This view has just been deselected.
	   */
	  view = nil;
	}

      /*
       * Control-click on a subview initiates a connection attempt.
       */
      if (view != nil && view != self && knob == IBNoneKnobPosition
	&& ([theEvent modifierFlags] & NSControlKeyMask) == NSControlKeyMask)
	{
	  NSPoint	dragPoint = [theEvent locationInWindow];
	  NSPasteboard	*pb;
	  NSString	*name = [document nameForObject: view];

	  pb = [NSPasteboard pasteboardWithName: NSDragPboard];
	  [pb declareTypes: [NSArray arrayWithObject: GormLinkPboardType]
		     owner: self];
	  [pb setString: name forType: GormLinkPboardType];
	  [NSApp displayConnectionBetween: view and: nil];

	  isLinkSource = YES;
	  [self dragImage: [NSApp linkImage]
		       at: dragPoint
		   offset: NSZeroSize
		    event: theEvent
	       pasteboard: pb
		   source: self
		slideBack: YES];
	  isLinkSource = NO;
	  [self makeSelectionVisible: YES];
	  return;
	}

      /*
       * Having determined the current selection, we now handle events.
       */
      if (view != nil)
	{
	  NSDate		*future = [NSDate distantFuture];
	  NSView		*subview;
	  BOOL			acceptsMouseMoved;
	  BOOL			dragStarted = NO;
	  unsigned		eventMask;
	  NSEvent		*e;
	  NSEventType		eType;
	  NSRect		r;
	  NSPoint		maxMouse;
	  NSPoint		minMouse;
	  NSRect		lastRect = [view frame];
	  NSPoint		lastPoint = mouseDownPoint;
	  NSPoint		point = mouseDownPoint;

	  eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
	    | NSLeftMouseDraggedMask | NSMouseMovedMask | NSPeriodicMask;
	  [[self window] setAcceptsMouseMovedEvents: YES];

	  /*
	   * Save window state info.
	   */
	  acceptsMouseMoved = [[self window] acceptsMouseMovedEvents];
	  [self lockFocus];

	  /*
	   * Get size limits for resizing or moving and calculate maximum
	   * and minimum mouse positions that won't cause us to exceed
	   * those limits.
	   */
	  if (view != self)
	    {
	      if (knob == IBNoneKnobPosition)
		{
		  NSRect	vf = [view frame];
		  NSRect	sf = [self frame];
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
	      else
		{
		  NSSize	max = [view maximumSizeFromKnobPosition: knob];
		  NSSize	min = [view minimumSizeFromKnobPosition: knob];

		  r = [self bounds];
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
	    }

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
		  point = [self convertPoint: [e locationInWindow]
				    fromView: nil];
		}
	      else if (NSEqualPoints(point, lastPoint) == NO)
		{
		  [[self window] disableFlushWindow];

		  if (view == self)
		    {
		      /*
		       * Handle wire-frame for selecting contents of window.
		       *
		       * FIXME - there has to be a more efficient way to
		       * restore the display under the box.
		       * FIXME - does the fact that we need to redisplay a
		       * rectangle slightly larger than the one we drew mean
		       * that there is a drawing bug?
		       */
		      r = NSRectFromPoints(lastPoint, mouseDownPoint);
		      lastPoint = point;
		      r.origin.x--;
		      r.origin.y--;
		      r.size.width += 2;
		      r.size.height += 2;
		      [self displayRect: r];
		      r = NSRectFromPoints(point, mouseDownPoint);
		      GormShowFrameWithKnob(r, IBNoneKnobPosition);
		    }
		  else
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

		      if (knob == IBNoneKnobPosition)
			{
			  if (dragStarted == NO)
			    {
			      /*
			       * Remove selection knobs before moving selection.
			       */
			      dragStarted = YES;
			      [self makeSelectionVisible: NO];
			    }
			  enumerator = [selection objectEnumerator];
			  while ((subview = [enumerator nextObject]) != nil)
			    {
			      NSRect	oldFrame = [subview frame];

			      r = oldFrame;
			      r.origin.x += xDiff;
			      r.origin.y += yDiff;
			      [subview setFrame: r];
			      [self displayRect: oldFrame];
			      [subview display];
			    }
			}
		      else
			{
			  r = GormExtBoundsForRect(lastRect);
			  r.origin.x--;
			  r.origin.y--;
			  r.size.width += 2;
			  r.size.height += 2;
			  [self displayRect: r];
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
			  GormShowFrameWithKnob(lastRect, knob);
			}
		    }

		  /*
		   * Flush any drawing performed for this event.
		   */
		  [[self window] enableFlushWindow];
		  [[self window] flushWindow];
		}
	      e = [NSApp nextEventMatchingMask: eventMask
				     untilDate: future
					inMode: NSEventTrackingRunLoopMode
				       dequeue: YES];
	      eType = [e type];
	    }
	  [NSEvent stopPeriodicEvents];

	  /*
	   * Perform any necessary cleanup.
	   */
	  if (view == self)
	    {
	      /*
	       * restore the display
	       */
	      r = NSRectFromPoints(lastPoint, mouseDownPoint);
	      r.origin.x--;
	      r.origin.y--;
	      r.size.width += 2;
	      r.size.height += 2;
	      [self displayRect: r];

	      /*
	       * Now finally check the selected rectangle to find the views in
	       * it and make them (if any) into our current selection.
	       */
	      point = [self convertPoint: [e locationInWindow]
				fromView: nil];
	      r = NSRectFromPoints(point, mouseDownPoint);
	      array = [NSMutableArray arrayWithCapacity: 8];
	      enumerator = [[self subviews] objectEnumerator];
	      while ((subview = [enumerator nextObject]) != nil)
		{
		  if (NSIntersectsRect(r, [subview frame]) == YES)
		    {
		      [array addObject: subview];
		    }
		}
	      if ([array count] > 0)
		{
		  [self selectObjects: array];
		}
	    }
	  else
	    {
	      if (knob != IBNoneKnobPosition)
		{
		  NSRect	redrawRect;

		  /*
		   * This was a subview resize, so we must clean up by removing
		   * the highlighted knob and the wireframe around the view.
		   */
		  r = GormExtBoundsForRect([view frame]);
		  r.origin.x--;
		  r.origin.y--;
		  r.size.width += 2;
		  r.size.height += 2;
		  redrawRect = r;
		  [view setFrame: lastRect];
		  r = GormExtBoundsForRect([view frame]);
		  r.origin.x--;
		  r.origin.y--;
		  r.size.width += 2;
		  r.size.height += 2;
		  redrawRect = NSUnionRect(r, redrawRect);
		  [self displayRect: redrawRect];
		  [self makeSelectionVisible: YES];
		}
	      if (NSEqualPoints(point, mouseDownPoint) == NO)
		{
		  /*
		   * A subview was moved or resized, so we must mark the
		   * doucment as edited.
		   */
		  [document touch];
		}
	    }
	  [self unlockFocus];
	  /*
	   * Restore state to what it was on entry.
	   */
	  [[self window] setAcceptsMouseMovedEvents: acceptsMouseMoved];
	}
      [self makeSelectionVisible: YES];
    }
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
  NSAssert(isClosed == NO, NSInternalInconsistencyException);
  if (original == nil)
    {
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
       * Swap ourselves in as a replacement for the original window
       * content view.
       */
      original = RETAIN([edited contentView]);
      [self setFrame: [original frame]];
      enumerator = [[original subviews] objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  [self addSubview: sub];
	}
      [edited setContentView: self];
      return NO;
    }
  return YES;
}

- (void) close
{
  NSAssert(isClosed == NO, NSInternalInconsistencyException);
  isClosed = YES;
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
  if ([selection count] > 0)
    {
      [document copyObjects: selection
		       type: IBViewPboardType
	       toPasteboard: [NSPasteboard generalPasteboard]];
    }
}

- (void) deactivate
{
  if (original != nil)
    {
      NSEnumerator	*enumerator;
      NSView		*sub;

      RETAIN(self);
      /*
       * Swap ourselves out and the original window content view in.
       */
      [original setFrame: [self frame]];
      [edited setContentView: original];
      enumerator = [[self subviews] objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  [original addSubview: sub];
	}
      DESTROY(original);
      RELEASE(self);
    }
}

- (void) dealloc
{
  if (isClosed == NO)
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
  NSArray	*a = [NSArray arrayWithArray: selection];
  unsigned	c = [a count];

  [self makeSelectionVisible: NO];
  [self selectObjects: [NSArray array]];
  while (c-- > 0)
    {
      id	obj = [a objectAtIndex: c];

      [document detachObject: obj];
      [self setNeedsDisplayInRect: [obj frame]];
      [obj removeFromSuperview];
    }
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
  /*
   * FIXME - handle this.
   * Notification that a drag failed/succeeded.
   */
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  if (isLinkSource == YES)
    return NSDragOperationLink;
  else
    return NSDragOperationCopy;
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSArray	*types;

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
  return [self draggingUpdated: sender];
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender
{
  if (dragType == IBViewPboardType)
    {
      return NSDragOperationCopy;
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      NSView	*sub = [super hitTest: loc];

      if (sub == self)
	{
	  sub = nil;
	}
      else if (sub == [NSApp connectSource])
	{
	  sub = nil;
	}
      [NSApp displayConnectionBetween: [NSApp connectSource] and: sub];
      return NSDragOperationLink;
    }
  else
    {
      return 0;
    }
}

- (void) drawSelection
{
  if ([selection count] > 0 && [selection lastObject] != edited)
    {
      NSEnumerator	*enumerator = [selection objectEnumerator];
      NSView		*view;

      [self lockFocus];
      while ((view = [enumerator nextObject]) != nil)
	{
	  GormDrawKnobsForRect([view frame]);
	}
      GormShowFastKnobFills();
      [self unlockFocus];
    }
}

- (id<IBDocuments>) document
{
  return document;
}

- (id) editedObject
{
  return edited;
}

- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  NSWindow	*win = (NSWindow*)anObject;
  NSView	*cv = [win contentView];
  NSView	*sub;
  NSEnumerator	*enumerator;

  /*
   * Initialize with current window content frame, move window subviews to
   * self, and replace window content view with self.
   */
  if ((self = [super initWithFrame: [cv frame]]) == nil)
    return nil;
  original = RETAIN(cv);
  enumerator = [[original subviews] objectEnumerator];
  while ((sub = [enumerator nextObject]) != nil)
    {
      [self addSubview: sub];
    }
  [win setContentView: self];

  ASSIGN(document, aDocument);
  ASSIGN(edited, anObject);
  selection = [NSMutableArray new];
  subeditors = [NSMutableArray new];

  /*
   * Permit views and connections to be dragged in to the window.
   */
  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    IBViewPboardType, GormLinkPboardType, nil]];

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

	      [self displayRect: rect];
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
  id<IBEditors>	sub;

  sub = [document editorForObject: anObject inEditor: self create: YES];
  /*
   * If we don't already have this subeditor, make a note of it so we
   * can close it later.
   */
  if ([subeditors indexOfObjectIdenticalTo: sub] == NSNotFound)
    {
      [subeditors addObject: sub];
    }
  return sub;
}

- (void) orderFront
{
  [edited orderFront: self];
}

- (void) pasteInSelection
{
  NSPasteboard	*pb = [NSPasteboard generalPasteboard];
  NSMutableArray	*array = [NSMutableArray arrayWithArray: selection];
  NSArray	*views;
  NSEnumerator	*enumerator;
  NSView	*sub;

  /*
   * Ask the document to get the copied views from the pasteboard and add
   * them to it's collection of known objects.
   */
  views = [document pasteType: IBViewPboardType
	       fromPasteboard: pb
		       parent: edited];
  /*
   * Now make all the views subviews of ourself.
   */
  enumerator = [views objectEnumerator];
  while ((sub = [enumerator nextObject]) != nil)
    {
      if ([sub isKindOfClass: [NSView class]] == YES)
	{
	  [self addSubview: sub];
	  [array addObject: sub];
	}
    }
  [self makeSelectionVisible: NO];
  [self selectObjects: array];
  [self makeSelectionVisible: YES];
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  if (dragType == IBViewPboardType)
    {
      NSPoint		loc = [sender draggedImageLocation];
      NSArray		*views;
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
       * Ask the document to get the dragged views from the pasteboard and add
       * them to it's collection of known objects.
       */
      views = [document pasteType: IBViewPboardType
		   fromPasteboard: dragPb
			   parent: edited];
      /*
       * Now make all the views subviews of ourself, setting their origin to
       * be the point at which they were dropped (converted from window
       * coordinates to our own coordinates).
       */
      loc = [self convertPoint: loc fromView: nil];
      enumerator = [views objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  NSRect	rect = [sub frame];

	  rect.origin = loc;
	  [sub setFrame: rect];
	  [self addSubview: sub];
	}
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      NSView	*sub = [super hitTest: loc];

      [NSApp displayConnectionBetween: [NSApp connectSource] and: sub];
      [NSApp startConnecting];
    }
  else
    {
      NSLog(@"Drop with unrecognized type (%@)!", dragType);
      dragType = nil;
      return NO;
    }
  dragType = nil;
  return YES;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  /*
   * Tell the source that we will accept the drop if we can.
   */
  if (dragType == IBViewPboardType)
    {
      /*
       * We can accept views dropped anywhere.
       */
      return YES;
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      NSView	*sub = [super hitTest: loc];

      /*
       * We can accept a link dropped on any of our subviews.
       */
      if (sub != nil && sub != self)
	{
	  return YES;
	}
    }
  return NO;
}

- (void) resetObject: (id)anObject
{
  [[self window] makeKeyAndOrderFront: self];
}

- (id) selectAll: (id)sender
{
  [self selectObjects: [self subviews]];
  return self;
}

- (void) selectObjects: (NSArray*)anArray
{
  if (anArray != selection)
    {
      unsigned	count;

      [selection removeAllObjects];
      [selection addObjectsFromArray: anArray];

      count = [selection count];

      /*
       * We can only select views that are direct subviews - discard others.
       */
      while (count-- > 0)
	{
	  id	o = [selection objectAtIndex: count];

	  if ([[self subviews] indexOfObjectIdenticalTo: o] == NSNotFound)
	    {
	      [selection removeObjectAtIndex: count];
	    }
	}
      /*
       * Now we must let the document (and hence the rest of the app) know
       * about our new selection.
       */
      [document setSelectionFromEditor: self];
    }
}

- (NSArray*) selection
{
  return [NSArray arrayWithArray: selection];
}

- (unsigned) selectionCount
{
  return [selection count];
}

- (void) validateEditing
{
}

- (BOOL) wantsSelection
{
  /*
   * We only want to be the selection owner if we are active (have been
   * swapped for the windows original content view) and if we have some
   * object selected.
   */
  if (original == nil)
    return NO;
  if ([selection count] == 0)
    return NO;
  return YES;
}

- (NSWindow*) window
{
  return [super window];
}
@end
