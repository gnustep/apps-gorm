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

static NSPoint
_constrainPointToBounds(NSPoint point, NSRect bounds)
{
  point.x = MAX(point.x, NSMinX(bounds));
  point.x = MIN(point.x, NSMaxX(bounds));
  point.y = MAX(point.y, NSMinY(bounds));
  point.y = MIN(point.y, NSMaxY(bounds));
  return point;
}

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



@interface	GormWindowEditor : NSView <IBEditors>
{
  id<IBDocuments>	document;
  NSWindow		*edited;
  NSView		*original;
  NSView                *edit_view;
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

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

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
  /*
   * Stop the subviews receiving events - we grab them all.
   */
  if ([super hitTest: loc] != nil)
    {
      return self;
    }
  return nil;
}

/* Called when the frame of a view object is changed. Takes care of
   validating the frame and updating the object */
- (BOOL) _validateFrame: (NSRect)frame 
	     forViewPtr: (id *)view_ptr 
	      withEvent: (NSEvent *)theEvent
		 update: (BOOL) update
{
  int rows, cols;
  NSSize cellSize, intercellSpace, minSize;
  id view = *view_ptr;
  BOOL isMatrix = [view isKindOfClass: [NSMatrix class]];
  BOOL isControl = [view isKindOfClass: [NSControl class]];
  BOOL isBox = [view isKindOfClass: [NSBox class]];

  /* What's the minimum size of a cell? */
  minSize = NSZeroSize;
  if (isMatrix)
    minSize = [[view prototype] cellSize];
  else if (isControl)
    minSize = [[view cell] cellSize];
  else if (isBox)
    {
      /* This is wrong. It depends on how we resize the subviews. Maybe we
       need to just set the frame, then determine the minimum size? */
      minSize = [(NSBox *)view minimumSize];
    }
  /* Sliders are a special case, I guess... */
  if ([view isKindOfClass: [NSSlider class]])
    {
      minSize = NSMakeSize(15, 15);
    }
  if (NSEqualSizes(minSize, NSZeroSize))
    minSize = NSMakeSize(20, 20);
  
  if (!isMatrix)
    {
      if (NSWidth(frame) < minSize.width)
	return NO;
      if (NSHeight(frame) < minSize.height)
	return NO;
      if (([theEvent modifierFlags] & NSAlternateKeyMask) 
	  != NSAlternateKeyMask || isControl == NO)
	return YES;
    }
  if (isBox)
    return YES;
  
  /* After here, everything is a matrix or will be converted to one */
  if (isMatrix)
    {
      cellSize = [view cellSize];
      intercellSpace = [view intercellSpacing];
      rows = [view numberOfRows];
      cols = [view numberOfColumns];
    }
  if (([theEvent modifierFlags] & NSControlKeyMask) == NSControlKeyMask)
    {
      /* Keep the cell size the same but increase the intercell spacing. */
      if ([view isKindOfClass: [NSForm class]] == NO)
	intercellSpace.width = (NSWidth(frame)-cellSize.width*cols)/(cols-1);
      intercellSpace.height = (NSHeight(frame)-cellSize.height*rows)/(rows-1);
      if (intercellSpace.width < 0)
	return NO;
      if (intercellSpace.height < 0)
	return NO;
      if ([view isKindOfClass: [NSForm class]] 
	  && NSWidth(frame) != NSWidth([view frame]))
	return NO;
      if (update)
	[view setIntercellSpacing: intercellSpace];
    }
  else if (([theEvent modifierFlags] & NSAlternateKeyMask) 
	   == NSAlternateKeyMask)
    {
      BOOL redisplay;
      int new_rows, new_cols;
      /* If possible convert the object to a matrix with the cell given by the
	 current object. If already a matrix, set the number of rows/cols
         based on the frame size. */
      if (!isMatrix)
	{
	  /* Convert to a matrix object */
	  NSMutableArray *array;
	  NSMatrix *matrix = [[NSMatrix alloc] initWithFrame: frame
					                mode: NSRadioModeMatrix
					           prototype: [view cell]
					        numberOfRows: 1
					     numberOfColumns: 1];
	  /* Remove this view and add the new matrix */
	  [edit_view addSubview: AUTORELEASE(matrix)];
	  //[self makeSelectionVisible: NO];
	  array = [NSMutableArray arrayWithArray: [self selection]];
	  [array removeObjectIdenticalTo: view];
	  [array addObject: matrix];
	  [self selectObjects: array];
	  [edit_view removeSubview: view];
	  *view_ptr = view = matrix;
	  cols = rows = 1;
	}
      if (NSWidth(frame) < (cellSize.width+intercellSpace.width)*cols
	  - intercellSpace.width)
	return NO;
      if (NSHeight(frame) < (cellSize.height+intercellSpace.height)*rows
	  - intercellSpace.height)
	return NO;
      new_cols = (NSWidth(frame)+intercellSpace.width)
	/ (cellSize.width + intercellSpace.width);
      new_rows = (NSHeight(frame)+intercellSpace.height)
	/ (cellSize.height+intercellSpace.height);
      if (new_rows < 0 || new_rows-rows > 50 
	  || new_cols < 0 || new_cols-cols > 50)
	{
	  /* Something wierd happened. Hopefully just a transient thing */
	  NSLog(@"Internal Error: Invalid frame during view resize (%d,%d)",
		new_rows, new_cols);
	  return YES;
	}
      redisplay = NO;
      if (new_cols > cols)
	{
	  if ([view isKindOfClass: [NSForm class]] == NO)
	    {
	      redisplay = YES;
	      while (new_cols - cols)
		{
		  [view addColumn];
		  new_cols--;
		}
	    }
	}
      if (new_rows > rows)
	{
	  int i;
	  redisplay = YES;
	  for (i = 0; i < new_rows-rows; i++)
	    {
	      if ([view isKindOfClass: [NSForm class]])
		[view addEntry: [NSString stringWithFormat: @"Form %0d", i+rows]];
	      else
		[view addRow];
	    }
	}
      if (redisplay)
	{
	  /* Redisplay regardless of 'update, since number of cells changed */
	  [view setFrame: frame];
	  [edit_view displayRect: [view frame]];
	}
    }
  else
    {
      /* Increase the cell size */
      cellSize = NSMakeSize((NSWidth(frame)+intercellSpace.width)/cols 
                              - intercellSpace.width, 
			    (NSHeight(frame)+intercellSpace.height)/rows 
                              - intercellSpace.height);
      /* Reasonable minimum size? - NSMatrix should do this? */
      if (cellSize.width < minSize.width)
	return NO;
      if (cellSize.height < minSize.height)
	return NO;
      if (update)
	[view setCellSize: cellSize];
    }
  return YES;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSEnumerator		*enumerator;
  NSView		*view = nil;
  IBKnobPosition	knob = IBNoneKnobPosition;
  NSPoint		mouseDownPoint;
  NSMutableArray	*array;

  mouseDownPoint = [edit_view convertPoint: [theEvent locationInWindow]
				fromView: nil];

  /*
   * If we have any subviews selected, we need to check to see if the knob
   * of any subview has been hit, or if a subview itself has been hit.
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
	      [edit_view lockFocus];
	      GormShowFrameWithKnob([view frame], knob);
	      [edit_view unlockFocus];
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
      view = [super hitTest: [theEvent locationInWindow]];
      /* Make sure we're selecting the proper view - must be a direct
	 decendant of the edit_view */
      while (view != nil && view != self 
	     && view != edit_view && [view superview] != edit_view)
	view = [view superview];
      if (view == self && edit_view != self)
	{
	  /* Clicked outside the edit view - just close the edit view(s) */
	  view = edit_view;
	  while (view != self)
	    {
	      NSRect r;
	      view = [view superview];
	      r = GormExtBoundsForRect([view frame]);
	      r.origin.x--;
	      r.origin.y--;
	      r.size.width += 2;
	      r.size.height += 2;
	      view = [view superview];
	      [view displayRect: r];
	    }
	  edit_view = self;
	}
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
   * Double-click on a subview opens the view for editing (if possible).
   */
  if (view != nil && view != self
    && ([theEvent clickCount] == 2))
    {
      BOOL isBox = [view isKindOfClass: [NSBox class]];
      if (isBox == YES)
	{
	  edit_view = [(NSBox *)view contentView];
	  [self makeSelectionVisible: NO];
	  [[view superview] lockFocus];
	  GormDrawOpenKnobsForRect([view frame]);
	  GormShowFastKnobFills();
	  [[view superview] unlockFocus];
	  [self selectObjects: [NSArray array]];
	}
      }

  /*
   * Having determined the current selection, we now handle events.
   */
  if (view != nil)
    {
      NSDate		*future = [NSDate distantFuture];
      NSView		*subview;
      BOOL		acceptsMouseMoved;
      BOOL		dragStarted = NO;
      unsigned		eventMask;
      NSEvent		*e;
      NSEventType	eType;
      NSRect		r;
      NSPoint		maxMouse;
      NSPoint		minMouse;
      NSRect		lastRect = [view frame];
      NSPoint		lastPoint = mouseDownPoint;
      NSPoint		point = mouseDownPoint;

      eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask
	| NSMouseMovedMask | NSPeriodicMask;
      [[self window] setAcceptsMouseMovedEvents: YES];

      /*
       * Save window state info.
       */
      acceptsMouseMoved = [[self window] acceptsMouseMovedEvents];
      [edit_view lockFocus];

      /*
       * Get size limits for resizing or moving and calculate maximum
       * and minimum mouse positions that won't cause us to exceed
       * those limits.
       */
      if (view != edit_view)
	{
	  if (knob == IBNoneKnobPosition)
	    {
	      NSRect	vf = [view frame];
	      NSRect	sf = [edit_view frame];
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

	      if (edit_view == self)
		r = [self bounds];
	      else
		r = [edit_view frame];
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
	      point = [edit_view convertPoint: [e locationInWindow]
				fromView: nil];
	      if (edit_view != self)
		point = _constrainPointToBounds(point, [edit_view bounds]);
	    }
	  else if (NSEqualPoints(point, lastPoint) == NO)
	    {
	      [[self window] disableFlushWindow];

	      if (view == edit_view)
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
		  [edit_view displayRect: r];
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
			  [edit_view displayRect: oldFrame];
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
		      [edit_view displayRect: r];
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
		      if ([self _validateFrame: r 
				    forViewPtr: &view
				     withEvent: theEvent
				        update: NO])
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
      if (view == edit_view)
	{
	  /*
	   * restore the display
	   */
	  r = NSRectFromPoints(lastPoint, mouseDownPoint);
	  r.origin.x--;
	  r.origin.y--;
	  r.size.width += 2;
	  r.size.height += 2;
	  [edit_view displayRect: r];

	  /*
	   * Now finally check the selected rectangle to find the views in
	   * it and make them (if any) into our current selection.
	   */
	  point = [edit_view convertPoint: [e locationInWindow]
			    fromView: nil];
	  r = NSRectFromPoints(point, mouseDownPoint);
	  array = [NSMutableArray arrayWithCapacity: 8];
	  enumerator = [[edit_view subviews] objectEnumerator];
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
	      [self _validateFrame: lastRect 
		        forViewPtr: &view 
		         withEvent: theEvent
			    update: YES];
	      [view setFrame: lastRect];
	      r = GormExtBoundsForRect([view frame]);
	      r.origin.x--;
	      r.origin.y--;
	      r.size.width += 2;
	      r.size.height += 2;
	      redrawRect = NSUnionRect(r, redrawRect);
	      [edit_view displayRect: redrawRect];
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
      [edit_view unlockFocus];
      /*
       * Restore state to what it was on entry.
       */
      [[self window] setAcceptsMouseMovedEvents: acceptsMouseMoved];
    }
  [self makeSelectionVisible: YES];
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

      [edit_view lockFocus];
      while ((view = [enumerator nextObject]) != nil)
	{
	  GormDrawKnobsForRect([view frame]);
	}
      GormShowFastKnobFills();
      [edit_view unlockFocus];
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
  /* The view that DnD and other mouseDown events go to (usually self) */
  edit_view = self;

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
	  [edit_view addSubview: sub];
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

      [self makeSelectionVisible: NO];
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
      loc = [edit_view convertPoint: loc fromView: nil];
      if (NSMouseInRect(loc, [edit_view bounds], NO) == NO)
	{
	  /* Dropped outside our view frame */
	  NSLog(@"Dropped outside current edit view");
	  dragType = nil;
	  return NO;
	}
      enumerator = [views objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  NSRect	rect = [sub frame];

	  rect.origin = loc;
	  [sub setFrame: rect];
	  [edit_view addSubview: sub];
	}
      [self selectObjects: views];
      [self displayIfNeeded];
      [self makeSelectionVisible: YES];
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

- (id) selectAllItems: (id)sender
{
  [self selectObjects: [self subviews]];
  return self;
}

- (void) selectObjects: (NSArray*)anArray
{
  if ([anArray isEqual: selection] == NO)
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

	  if ([[edit_view subviews] indexOfObjectIdenticalTo: o] == NSNotFound)
	    {
	      [selection removeObjectAtIndex: count];
	    }
	}
    }
  /*
   * Now we must let the document (and hence the rest of the app) know
   * about our new selection.  If there is nothing in it, make sure
   * that our edited window is selected instead.
   */
  if ([selection count] > 0)
    {
      [document setSelectionFromEditor: self];
    }
  else
    {
      GormObjectEditor	*ed;

      ed = [GormObjectEditor editorForDocument: document];
      [ed selectObjects: [NSArray arrayWithObject: edited]];
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
