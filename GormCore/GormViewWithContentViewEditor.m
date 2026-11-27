/* GormViewWithContentViewEditor.m
 *
 * Copyright (C) 2002, 2026 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2002, 2026
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import <AppKit/AppKit.h>

#import "GormPrivate.h"
#import "GormViewWithContentViewEditor.h"
#import "GormPlacementInfo.h"
#import "GormSplitViewEditor.h"
#import "GormViewKnobs.h"
#import "GormInternalViewEditor.h"
#import "GormDocument.h"
#import "GormGroupProtocol.h"
#import "GormGroupViews.h"

// Forward declaration...
@class GormBoxEditor;
@class GormSplitViewEditor;
@class GormScrollViewEditor;

@interface GormViewEditor (Private)
- (NSRect) _displayMovingFrameWithHint: (NSRect) frame
                     andPlacementInfo: (GormPlacementInfo *)gpi;
@end

static NSImage *verticalImage;
static NSImage *horizontalImage;

@implementation GormViewWithContentViewEditor

- (id) initWithObject: (id) anObject
  	   inDocument: (id<IBDocuments>)aDocument
{
  _displaySelection = YES;
  //GuideLine
  [[NSNotificationCenter defaultCenter] addObserver:self 
					selector:@selector(guideline:)
					name: GormToggleGuidelineNotification
					object:nil];
  _followGuideLine = YES;
  self = [super initWithObject: anObject
		inDocument: aDocument];
  if (horizontalImage == nil)
    {
      NSCachedImageRep *rep;
      horizontalImage = [[NSImage allocWithZone:(NSZone *)[(NSObject *)self zone]]
                          initWithSize: NSMakeSize(3000, 2)];
      rep = [[NSCachedImageRep allocWithZone:
                                  (NSZone *)[(NSObject *)self zone]]
              initWithSize:NSMakeSize(3000, 2)
               depth:[NSWindow defaultDepthLimit]
               separate:YES
               alpha:YES];

      [horizontalImage addRepresentation: rep];
      RELEASE(rep);
      verticalImage = [[NSImage allocWithZone:(NSZone *)[(NSObject *)self zone]]
                          initWithSize: NSMakeSize(2, 3000)];
      rep = [[NSCachedImageRep allocWithZone:
                                  (NSZone *)[(NSObject *)self zone]]
              initWithSize:NSMakeSize(2, 3000)
               depth:[NSWindow defaultDepthLimit]
               separate:YES
               alpha:YES];

      [verticalImage addRepresentation: rep];
      RELEASE(rep);
    }

  return self;
}

- (void) mouseDown: (NSEvent *) theEvent
{
  /* A connection gesture must precede knob and marquee selection handling,
   * including when the canvas has no parent view editor. */
  if ([theEvent modifierFlags] & NSControlKeyMask)
    {
      [super mouseDown: theEvent];
      return;
    }

  BOOL onKnob = NO;

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

  if (viewWindow == nil && [parent isOpened] == NO)
    {
      NSDebugLog(@"md %@ calling my parent %@", self, parent);
      [parent mouseDown: theEvent];
      return;
    }

  // are we on the knob of a selected view ?
  {
    NSInteger count = [selection count];
    NSInteger i;
    GormViewEditor *knobView = nil;
    IBKnobPosition	knob = IBNoneKnobPosition;
    NSPoint mouseDownPoint;

    for ( i = 0; i < count; i++ )
      {
	mouseDownPoint = [[[selection objectAtIndex: i] superview]
			   convertPoint: [theEvent locationInWindow]
			   fromView: nil];

	knob = GormKnobHitInRect([[selection objectAtIndex: i] frame],
				 mouseDownPoint);

	if (knob != IBNoneKnobPosition)
	  {
	    knobView = [selection objectAtIndex: i];
	    [self selectObjects: [NSMutableArray arrayWithObject: knobView]];
	    // we should set knobView as the only view selected
	    break;
	  }
      }

    if ( openedSubeditor != nil )
      {
	mouseDownPoint = [[openedSubeditor superview]
			   convertPoint: [theEvent locationInWindow]
			   fromView: nil];

	knob = GormKnobHitInRect([openedSubeditor frame],
				 mouseDownPoint);
	if (knob != IBNoneKnobPosition)
	  {
	    knobView = openedSubeditor;
	    // we should take back the selection
	    // we should select openedSubeditor only
	    [self selectObjects: [NSMutableArray arrayWithObject: knobView]];
	    [[self window] disableFlushWindow];
	    [self display];
	    [[self window] enableFlushWindow];
	    [[self window] flushWindow];
	  }
      }


    if (knobView != nil)
      {
	[self handleMouseOnKnob: knob
	      ofView: knobView
	      withEvent: theEvent];
	[self setNeedsDisplay: YES];
	return;
      }
  }

  {
    GormViewEditor *editorView;

    // get the view we are on
    {
      NSPoint mouseDownPoint;
      NSView *result = nil;
      GormViewEditor *theParent = nil;

      mouseDownPoint = [self
			 convertPoint: [theEvent locationInWindow]
			 fromView: nil];

      result = [_editedObject hitTest: mouseDownPoint];

      // we should get a result which is a direct subeditor
      {
	id temp = result;

	if ([temp isKindOfClass: [GormViewEditor class]])
	  theParent = [(GormViewEditor *)temp parent];
	while ((temp != nil) && (theParent != self) && (temp != self))
	  {
	    temp = [temp superview];
	    while ((temp != nil)
		   && ![temp isKindOfClass: [GormViewEditor class]])
	      {
		temp = [temp superview];
	      }
	    if (temp != nil)
	      {
		theParent = [(GormViewEditor *)temp parent];
	      }
	  }
	if (temp != nil)
	  {
	    result = temp;
	  }
	else
	  {
	    NSDebugLog(@"WARNING -- strange case");
	    result = self;
	  }
      }


      if ([result isKindOfClass: [GormViewEditor class]])
	{
	}
      else
	{
	  result = nil;
	}

      // this is the direct subeditor the mouse was clicked on
      // (or self)
      editorView = (GormViewEditor *)result;
    }

    if (([theEvent clickCount] == 2)
	&& [editorView isKindOfClass: [GormViewWithSubviewsEditor class]]
	&& ([(id)editorView canBeOpened] == YES)
	&& (editorView != self))
      // Let's open a subeditor
      {
	[(GormViewWithSubviewsEditor *) editorView setOpened: YES];
	[self silentlyResetSelection];
	openedSubeditor = (GormViewWithSubviewsEditor *) editorView;
	[self setNeedsDisplay: YES];
	return;
      }

    if (editorView != self)
      {
	[self handleMouseOnView: editorView
	      withEvent: theEvent];
      }
    else // editorView == self
      {
	NSEvent *e;
	unsigned eventMask;
	NSDate *future = [NSDate distantFuture];
	NSRect oldRect = NSZeroRect;
	NSPoint p, oldp;
	NSRect r = NSZeroRect;
	float x, y, w, h;

	oldp = [self convertPoint: [theEvent locationInWindow] fromView: nil];

	eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;


	if (!([theEvent modifierFlags] & NSShiftKeyMask))
	  [self selectObjects: [NSMutableArray array]];
	[[self window] disableFlushWindow];
	[self setNeedsDisplay: YES];
	[self displayIfNeeded];
	[[self window] enableFlushWindow];
	[[self window] flushWindowIfNeeded];

	e = [NSApp nextEventMatchingMask: eventMask
		   untilDate: future
		   inMode: NSEventTrackingRunLoopMode
		   dequeue: YES];
	[self lockFocus];
	while ([e type] != NSLeftMouseUp)
	  {
	    p = [self convertPoint: [e locationInWindow] fromView: nil];

	    x = (p.x >= oldp.x) ? oldp.x : p.x;
	    y = (p.y >= oldp.y) ? oldp.y : p.y;
	    w = MAX(p.x, oldp.x) - MIN(p.x, oldp.x);
	    w = (w == 0) ? 1 : w;
	    h = MAX(p.y, oldp.y) - MIN(p.y, oldp.y);
	    h = (h == 0) ? 1 : h;

	    r = NSMakeRect(x, y, w, h);

	    if (NSEqualRects(oldRect, NSZeroRect) == NO)
	      {
		[verticalImage
		  compositeToPoint: NSMakePoint(NSMinX(oldRect), NSMinY(oldRect))
		  fromRect: NSMakeRect(0.0, 0.0, 1.0, oldRect.size.height)
		  operation: NSCompositeCopy];
		[verticalImage
		  compositeToPoint: NSMakePoint(NSMaxX(oldRect)-1, NSMinY(oldRect))
		  fromRect: NSMakeRect(1.0, 0.0, 1.0, oldRect.size.height)
		  operation: NSCompositeCopy];

		[horizontalImage
		  compositeToPoint: NSMakePoint(NSMinX(oldRect), NSMinY(oldRect))
		  fromRect: NSMakeRect(0.0, 0.0, oldRect.size.width, 1.0)
		  operation: NSCompositeCopy];
		[horizontalImage
		  compositeToPoint: NSMakePoint(NSMinX(oldRect), NSMaxY(oldRect)-1)
		  fromRect: NSMakeRect(0.0, 1.0, oldRect.size.width, 1.0)
		  operation: NSCompositeCopy];
	      }

	    {
	      NSRect wr;
	      wr = [self convertRect: r
			 toView: nil];

	      [verticalImage lockFocus];
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMinX(wr), NSMinY(wr),
				    1.0, r.size.height),
			 NSMakePoint(0.0, 0.0));
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMaxX(wr)-1, NSMinY(wr),
				    1.0, r.size.height),
			 NSMakePoint(1.0, 0.0));
	      [verticalImage unlockFocus];

	      [horizontalImage lockFocus];
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMinX(wr), NSMinY(wr),
				    r.size.width, 1.0),
			 NSMakePoint(0.0, 0.0));
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMinX(wr), NSMaxY(wr)-1,
				    r.size.width, 1.0),
			 NSMakePoint(0.0, 1.0));
	      [horizontalImage unlockFocus];
	    }

	    [[NSColor darkGrayColor] set];
	    NSFrameRect(r);
	    oldRect = r;

	    [[self window] enableFlushWindow];

	    [[self window] flushWindow];
	    [[self window] disableFlushWindow];


	    e = [NSApp nextEventMatchingMask: eventMask
		       untilDate: future
		       inMode: NSEventTrackingRunLoopMode
		       dequeue: YES];
	  }

	if (NSEqualRects(r, NSZeroRect) == NO)
	  {
	    [verticalImage
	      compositeToPoint: NSMakePoint(NSMinX(r), NSMinY(r))
	      fromRect: NSMakeRect(0.0, 0.0, 1.0, r.size.height)
	      operation: NSCompositeCopy];
	    [verticalImage
	      compositeToPoint: NSMakePoint(NSMaxX(r)-1, NSMinY(r))
	      fromRect: NSMakeRect(1.0, 0.0, 1.0, r.size.height)
	      operation: NSCompositeCopy];

	    [horizontalImage
	      compositeToPoint: NSMakePoint(NSMinX(r), NSMinY(r))
	      fromRect: NSMakeRect(0.0, 0.0, r.size.width, 1.0)
	      operation: NSCompositeCopy];
	    [horizontalImage
	      compositeToPoint: NSMakePoint(NSMinX(r), NSMaxY(r)-1)
	      fromRect: NSMakeRect(0.0, 1.0, r.size.width, 1.0)
	      operation: NSCompositeCopy];
	  }


	{
	  NSMutableArray *array;
	  NSEnumerator *enumerator;
	  NSView *subview;


	  if ([theEvent modifierFlags] & NSShiftKeyMask)
	    array = [NSMutableArray arrayWithArray: selection];
	  else
	    array = [NSMutableArray arrayWithCapacity: 8];
	  enumerator = [[_editedObject subviews] objectEnumerator];
	  while ((subview = [enumerator nextObject]) != nil)
	    {
	      if ((NSIntersectsRect([_editedObject convertRect: r fromView: self],
                               [subview frame]) == YES)
		  && [subview isKindOfClass: [GormViewEditor class]])
		{
		  [array addObject: subview];
		}
	    }

	  if ([array count] > 0)
	    {
	      [self selectObjects: array];
	    }
	  [self displayIfNeeded];

	  [self unlockFocus];
	  [[self window] enableFlushWindow];

	  [[self window] flushWindow];
	}

      }

  }
}

- (void) addViewToDocument: (NSView *)view
{
  if ([view respondsToSelector: @selector(editedObject)])
    {
      id raw = [(id)view editedObject];
      if (raw != nil && [raw isKindOfClass: [NSView class]])
        {
          view = (NSView *)raw;
        }
    }

  NSView *par = [view superview];

  if([par isKindOfClass: [GormViewEditor class]])
    {
      par = [(GormViewEditor *)par editedObject];
    }

  [document attachObject: view toParent: par];
}

-(void) guideline:(NSNotification *)notification
{
  if ( _followGuideLine )
    _followGuideLine = NO;
  else 
    _followGuideLine = YES;
}

- (void) moveSelectionByX: (float)x 
		     andY: (float)y
{
  NSInteger i;
  NSInteger count = [selection count];

  for (i = 0; i < count; i++)
    {
      id v = [selection objectAtIndex: i];
      NSRect f = [v frame];
      
      f.origin.x += x;
      f.origin.y += y;

      [v setFrameOrigin: f.origin];
    }
}

- (void) resizeSelectionByX: (float)x 
		       andY: (float)y
{
  NSInteger i;
  NSInteger count = [selection count];

  for (i = 0; i < count; i++)
    {
      id v = [selection objectAtIndex: i];
      NSRect f = [v frame];
      
      f.size.width += x;
      f.size.height += y;

      [v setFrameSize: f.size];
    }
}

- (void) keyDown: (NSEvent *)theEvent
{
  NSString *characters = [theEvent characters];
  unichar character = 0;
  float moveBy = 1.0;

  if ([characters length] > 0)
    {
      character = [characters characterAtIndex: 0];
    }

  if (([theEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask)
    {
      if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
	  moveBy = 10.0;
	}
      
      if ([selection count] == 1)
	{
	  switch (character)
	    {
	    case NSUpArrowFunctionKey:
	      [self resizeSelectionByX: 0 andY: 1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSDownArrowFunctionKey:
	      [self resizeSelectionByX: 0 andY: -1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSLeftArrowFunctionKey:
	      [self resizeSelectionByX: -1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSRightArrowFunctionKey:
	      [self resizeSelectionByX: 1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    }
	}
    }
  else
    {
      if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
	  moveBy = 10.0;
	}
      
      if ([selection count] > 0)
	{
	  switch (character)
	    {
	    case NSUpArrowFunctionKey:
	      [self moveSelectionByX: 0 andY: 1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSDownArrowFunctionKey:
	      [self moveSelectionByX: 0 andY: -1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSLeftArrowFunctionKey:
	      [self moveSelectionByX: -1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSRightArrowFunctionKey:
	      [self moveSelectionByX: 1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    }
	}
    }
  [super keyDown: theEvent];

}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  if ([super acceptsTypeFromArray: types])
    {
      return YES;
    }

  return [types containsObject: IBViewPboardType];
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
      NSInteger i;
      NSInteger count = [selection count];

      for ( i = 0; i < count ; i++ )
	{
	  GormDrawKnobsForRect([self convertRect:
				       [[selection objectAtIndex: i] bounds]
				     fromView: [selection objectAtIndex: i]]);
	  GormShowFastKnobFills();
	}
    }

}

- (NSArray *) editedViewsFromSelection
{
  NSMutableArray *sel = [NSMutableArray arrayWithCapacity: [selection count]];
  NSEnumerator *en = [selection objectEnumerator];
  id e = nil;

  [self makeSubeditorResign];

  while ((e = [en nextObject]) != nil)
    {
      id v = [e editedObject];

      // Deactivate nested subeditors first, then deactivate wrapper.
      if ([e respondsToSelector: @selector(deactivateSubeditors)])
        {
          [e deactivateSubeditors];
        }

      if ([e respondsToSelector: @selector(deactivate)])
        {
          [e deactivate];
        }

      if ([v respondsToSelector: @selector(editedObject)])
        {
          v = [v editedObject];
        }

      // Defensive unwrap in case an editor wrapper slips through.
      if ([v isKindOfClass: [NSView class]])
        {
          [sel addObject: v];
        }
    }

  return sel;
}

- (NSRect) computeBoundingRectForViews: (NSArray *)views
{
  NSRect boundingRect = NSZeroRect;
  NSEnumerator *en = [views objectEnumerator];
  id view = nil;
  
  while ((view = [en nextObject]) != nil)
    {
      if ([view isKindOfClass: [NSView class]])
        {
          NSRect viewFrame = [view frame];
          if (NSIsEmptyRect(boundingRect))
            {
              boundingRect = viewFrame;
            }
          else
            {
              boundingRect = NSUnionRect(boundingRect, viewFrame);
            }
        }
    }
    
  return boundingRect;
}

- (void) groupSelectionInView: (id)view
{
  GormDocument *doc = (GormDocument *)document;
  NSArray *viewSelection = nil;

  if ([view respondsToSelector: @selector(editedObject)])
    {
      id raw = [view editedObject];
      if (raw != nil && [raw isKindOfClass: [NSView class]])
        {
          view = raw;
        }
    }

  if (![view isKindOfClass: [NSView class]])
    {
      return;
    }

  // Validate count...
  if ([view respondsToSelector: @selector(validateCount:)])
    {
      if (![view validateCount: [selection count]])
        {
          return;
        }
    }

  viewSelection = [self editedViewsFromSelection];
  if ([viewSelection count] == 0)
    {
      return;
    }

  // Compute rect...
  NSRect rect = NSZeroRect;
  if ([view respondsToSelector: @selector(computeRectForViews:)])
    {
      rect = [view computeRectForViews: viewSelection];
    }
  else
    {
      // Fallback: compute bounding rect manually
      rect = [self computeBoundingRectForViews: viewSelection];
    }
  // Order views and set orientation BEFORE setting the frame.
  // Setting the frame on NSSplitView triggers adjustSubviews internally;
  // isVertical must already be set at that point so the layout is correct.
  NSArray *sortedViews = [view orderSelectionForViews: viewSelection];

  [view setFrame: rect];

  [view addViews: sortedViews];

  // Add view to the edited object directly. We must NOT use
  // [parentObject contentView] here because after editor activation
  // [window contentView] returns the GormInternalViewEditor itself,
  // not the original NSView. Adding view there would put it outside
  // the subtree searched by mouseDown:'s [_editedObject hitTest:],
  // making the grouped view unselectable.
  [_editedObject addSubview: view];
  [self addViewToDocument: (NSView *)view];

  // Get the editor for the object...
  id editor = [doc editorForObject: view inEditor: self create: YES];

  /*
   * Grouping into container views like NSBox/NSScrollView can auto-create an
   * internal editor for content/document view. Keep only the container editor
   * active here to avoid leaving an untracked internal editor in the tree.
   */
  {
    NSView *internalRoot = nil;

    if ([view respondsToSelector: @selector(contentView)])
      {
        internalRoot = [(id)view contentView];
      }
    else if ([view respondsToSelector: @selector(documentView)])
      {
        internalRoot = [(id)view documentView];
      }

    if (internalRoot != nil)
      {
        id internalEditor = [doc editorForObject: internalRoot create: NO];
        if (internalEditor != nil && internalEditor != editor &&
            [internalEditor respondsToSelector: @selector(close)])
          {
            [internalEditor close];
          }
      }
  }

  // Select objects...
  [self selectObjects: [NSArray arrayWithObject: editor]];
}

- (void) groupSelectionInSplitView
{
  [self groupSelectionInView: [[NSSplitView alloc] initWithFrame: NSZeroRect]];
}

- (void) groupSelectionInBox
{
  [self groupSelectionInView: [[NSBox alloc] initWithFrame: NSZeroRect]];
}

- (void) groupSelectionInView
{
  [self groupSelectionInView: [[NSView alloc] initWithFrame: NSZeroRect]];
}

- (void) groupSelectionInScrollView
{
  [self groupSelectionInView: [[NSScrollView alloc] initWithFrame: NSZeroRect]];
}

- (void) ungroup
{
  if ([selection count] != 1)
    {
      return;
    }

  id containerEditor = [selection objectAtIndex: 0];
  if (![containerEditor respondsToSelector: @selector(destroyAndListSubviews)])
    {
      return;
    }

  id containerView = [containerEditor editedObject];

  // Step 1: destroyAndListSubviews deactivates sub-editors, converts frames
  // back to our coordinate space, closes the container editor, and returns
  // the extracted views. The views are now detached from the container's
  // view hierarchy but still exist in the document model.
  NSArray *extractedViews = [containerEditor destroyAndListSubviews];

  if (!extractedViews || [extractedViews count] == 0)
    {
      // Container was empty. Just remove it from view hierarchy and done.
      [containerView removeFromSuperview];
      [self setNeedsDisplay: YES];
      return;
    }

  // Step 2: Immediately remove the container from the view hierarchy so it
  // doesn't interfere with the extracted views' attachment.
  [containerView removeFromSuperview];

  // Step 3: Add extracted views to _editedObject and update document parents.
  NSMutableArray *newSelection = [NSMutableArray arrayWithCapacity: [extractedViews count]];
  NSEnumerator *en = [extractedViews objectEnumerator];
  id view = nil;

  while ((view = [en nextObject]) != nil)
    {
      if (![view isKindOfClass: [NSView class]])
        {
          continue;
        }

      if ([view respondsToSelector: @selector(editedObject)])
        {
          view = [view editedObject];
        }

      if (![view isKindOfClass: [NSView class]])
        {
          continue;
        }

      // Add to edited object's view hierarchy
      [_editedObject addSubview: view];

      // Update document parent connector. This adjusts the view's parent
      // to point to _editedObject instead of the old container.
      [self addViewToDocument: view];

      // Create/activate editor for the extracted view
      id viewEditor = [document editorForObject: view
                                       inEditor: self
                                         create: YES];
      if (viewEditor != nil)
        {
          [newSelection addObject: viewEditor];
        }
    }

  // Remove old container from document model now that children were
  // reattached under _editedObject.
  [document detachObject: containerView closeEditor: NO];

  // Step 4: Select and display the extracted views
  [self selectObjects: newSelection];
  [self setNeedsDisplay: YES];
}

- (void) pasteInView: (NSView *)view
{
  NSPasteboard	 *pb = [NSPasteboard generalPasteboard];
  NSMutableArray *array = [NSMutableArray array];
  NSArray	 *views = nil;
  NSEnumerator	 *enumerator = nil;
  NSView         *sub = nil;

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
	  //
	  // Correct the frame if it is outside of the containing view.
	  // this prevents issues where the subview is placed outside the
	  // viewable region of the superview.
	  //
	  if(NSContainsRect([view frame], [sub frame]) == NO)
	    {
	      NSRect newFrame = [sub frame];
	      newFrame.origin.x = 0;
	      newFrame.origin.y = 0;
	      [sub setFrame: newFrame];
	    }

	  [view addSubview: sub];
	  [self addViewToDocument: sub];
	  [array addObject:
		   [document editorForObject: sub 
			     inEditor: self 
			     create: YES]];
	}
    }

  [self selectObjects: array];
}

@end
