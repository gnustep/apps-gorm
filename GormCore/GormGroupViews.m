/* GormGroupViews.m
 *
 * Copyright (C) 2026 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2026
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

#import <AppKit/AppKit.h>

#import "GormGroupProtocol.h"
#import "GormViewEditor.h"

// Utility function for sorting views
NSComparisonResult _sortViews(id view1, id view2, void *context)
{
  BOOL isVertical = *((BOOL *)context);
  NSComparisonResult order = NSOrderedSame;
  NSRect rect1 = [view1 frame];
  NSRect rect2 = [view2 frame];

  if (!isVertical)
    {
      CGFloat y1 = rect1.origin.y;
      CGFloat y2 = rect2.origin.y;

      if (y1 == y2) 
	order = NSOrderedSame;
      else
	order = (y1 > y2) ? NSOrderedAscending : NSOrderedDescending;
    }
  else
    {
      CGFloat x1 = rect1.origin.x;
      CGFloat x2 = rect2.origin.x;

      if (x1 == x2) 
	order = NSOrderedSame;
      else
	order = (x1 < x2) ? NSOrderedAscending : NSOrderedDescending;
    }

  return order;
}

// MARK: - NSView utility methods for grouping

@implementation NSView (GormGroupUtils)

- (NSArray *) sortByPosition: (NSArray *)subviews
                  isVertical: (BOOL *)isVertical
{
  NSMutableArray *array = [subviews mutableCopy];
  NSArray *result = [array sortedArrayUsingFunction: _sortViews
                                            context: isVertical];
  [array release];
  return result;
}

- (BOOL) shouldBeVertical: (NSArray *)subviews
{
  NSEnumerator *enumerator = [subviews objectEnumerator];
  id subview = nil;

  NSRect prevRect = NSZeroRect;
  NSInteger count = 0;

  // Iterate over the list of views to determine orientation
  while ((subview = [enumerator nextObject]) != nil)
    {
      NSRect currRect = [subview frame];

      if (!NSEqualRects(prevRect, NSZeroRect))
        {
          // Use strict range-overlap tests so that touching views
          // (gap == 0) are not misclassified.
          BOOL xOverlap = (NSMinX(prevRect) < NSMaxX(currRect)) &&
                          (NSMinX(currRect) < NSMaxX(prevRect));
          BOOL yOverlap = (NSMinY(prevRect) < NSMaxY(currRect)) &&
                          (NSMinY(currRect) < NSMaxY(prevRect));

          if (yOverlap && !xOverlap)
            count++;  // side-by-side: y-ranges overlap, x-ranges don't
          else if (xOverlap && !yOverlap)
            count--;  // stacked: x-ranges overlap, y-ranges don't
          // else: ambiguous (diagonal or fully overlapping) — no vote
        }

      prevRect = currRect;
    }

  // Positive count → side-by-side → NSSplitView vertical=YES (vertical dividers)
  // Negative count → stacked     → NSSplitView vertical=NO  (horizontal dividers)
  return (count >= 0);
}

- (NSArray *) buildFramesForViews: (NSArray *)views
                    withUnionRect: (NSRect)unionRect
{
  NSMutableArray *result = [NSMutableArray array];
  NSEnumerator *en = [views objectEnumerator];
  NSView *view = nil;
  NSPoint contentOrigin = [self frame].origin;

  while ((view = [en nextObject]) != nil)
    {
      NSRect viewFrame = [view frame];
      
      // Adjust frame relative to union rect and content origin
      viewFrame.origin.x -= unionRect.origin.x;
      viewFrame.origin.y -= unionRect.origin.y;
      viewFrame.origin.x -= contentOrigin.x;
      viewFrame.origin.y -= contentOrigin.y;
      
      [view setFrame: viewFrame];
      [result addObject: view];
    }

  return result;
}

/**
 * Computes the bounding rectangle that should contain all the given views.
 * This determines the position and size of the new container view.
 */
- (NSRect) _computeContainerRectForViews: (NSArray *)views
{
  NSEnumerator *en = [views objectEnumerator];
  NSRect containerRect = NSZeroRect;
  NSView *view = nil;

  // Calculate the union of all view frames to determine container bounds
  while ((view = [en nextObject]) != nil)
    {
      containerRect = NSUnionRect(containerRect, [view frame]);
    }

  return containerRect;
}

/**
 * Prepares views for grouping by deactivating any editors and 
 * collecting them into a mutable array.
 */
- (NSMutableArray *) _prepareViewsForGrouping: (NSArray *)views
{
  NSMutableArray *preparedViews = [NSMutableArray arrayWithCapacity: [views count]];
  NSEnumerator *en = [views objectEnumerator];
  id view = nil;

  while ((view = [en nextObject]) != nil)
    {
      // Deactivate any editors associated with this view
      if ([view respondsToSelector: @selector(deactivate)]) 
        {
          [view deactivate];
        }
      [preparedViews addObject: view];
    }

  return preparedViews;
}

/**
 * Positions the subviews within the container by adjusting their frames
 * relative to the container's coordinate system.
 */
- (void) _positionSubviewsInContainer: (NSArray *)views
                        containerRect: (NSRect)containerRect
{
  NSEnumerator *en = [views objectEnumerator];
  NSView *view = nil;
  NSPoint containerOrigin = containerRect.origin;
  NSPoint selfOrigin = [self frame].origin;

  while ((view = [en nextObject]) != nil)
    {
      NSRect viewFrame = [view frame];
      
      // Convert view frame to be relative to the container's coordinate system
      viewFrame.origin.x -= containerOrigin.x;
      viewFrame.origin.y -= containerOrigin.y;
      
      // Adjust relative to self's frame if needed
      viewFrame.origin.x -= selfOrigin.x;
      viewFrame.origin.y -= selfOrigin.y;
      
      [view setFrame: viewFrame];
    }
}

@end

// MARK: - Protocol implementations for different view types

@implementation NSSplitView (GormGroupProtocol)

- (BOOL) validateCount: (NSUInteger)count
{
  // Split views require at least 2 subviews
  return (count >= 2);
}

- (NSRect) computeRectForViews: (NSArray *)views
{
  if ([views count] == 0) {
    return NSZeroRect;
  }
  
  // Step 1: Determine the position and size of the new container view
  NSRect newViewRect = [self _computeContainerRectForViews: views];
  
  // Step 2: Prepare views for grouping (deactivate editors, etc.)
  NSMutableArray *preparedViews = [self _prepareViewsForGrouping: views];
  
  // Step 3: Calculate and set positions of subviews relative to container
  [self _positionSubviewsInContainer: preparedViews 
                       containerRect: newViewRect];
  
  // Step 4: Add processed views to this split view
  NSEnumerator *viewEnum = [preparedViews objectEnumerator];
  NSView *subview = nil;
  while ((subview = [viewEnum nextObject]) != nil)
    {
      [self addSubview: subview];
    }
  
  return newViewRect;
}

- (NSArray *) orderSelectionForViews: (NSArray *)selection
{
  BOOL vertical = [self shouldBeVertical: selection];
  NSArray *array = [self sortByPosition: selection
                             isVertical: &vertical];

  [self setVertical: vertical];
  return array;
}

@end

@implementation NSBox (GormGroupProtocol)

- (NSRect) computeRectForViews: (NSArray *)views
{
  if ([views count] == 0) {
    return NSZeroRect;
  }
  
  NSView *contentView = [self contentView];
  
  // Step 1: Determine the position and size of the new container view
  NSRect newViewRect = [self _computeContainerRectForViews: views];
  
  // Step 2: Prepare views for grouping (deactivate editors, etc.)
  NSMutableArray *preparedViews = [self _prepareViewsForGrouping: views];
  
  // Step 3: Calculate and set positions of subviews relative to container
  [contentView _positionSubviewsInContainer: preparedViews 
                              containerRect: newViewRect];
  
  // Step 4: Add processed views to content view
  NSEnumerator *viewEnum = [preparedViews objectEnumerator];
  NSView *subview = nil;
  while ((subview = [viewEnum nextObject]) != nil)
    {
      [contentView addSubview: subview];
    }

  return newViewRect;
}

// NSBox adds directly to its contentView...
- (void) addViews: (NSArray *)subviews
{
  NSView *contentView = [(NSBox *)self contentView];
  NSEnumerator *en = [subviews objectEnumerator];
  id v = nil;

  /*
      // Move each child into the box's content view, adjusting its origin
  for (NSView *childView in viewsToGroup)
    {
      NSRect frame = [childView frame];

      // Update the parent connector to point to the new box
      NSArray *old = [document connectorsForSource: childView
                                           ofClass: [NSNibConnector class]];
      if ([old count] > 0)
        {
          [[old objectAtIndex: 0] setDestination: box];
        }

      [childView removeFromSuperview];
      [contentView addSubview: childView];

      // Adjust position relative to contentView origin
      frame.origin.x -= unionRect.origin.x;
      frame.origin.y -= unionRect.origin.y;
      frame.origin.x -= contentFrame.origin.x;
      frame.origin.y -= contentFrame.origin.y;
      [childView setFrame: frame];

      [document editorForObject: childView
                       inEditor: editor
                         create: YES];
    }

   */
  
  while ((v = [en nextObject]) != nil)
    {
      [contentView addSubview: v];
    }
}

@end

@implementation NSView (GormGroupProtocol)

- (BOOL) validateCount: (NSUInteger)count
{
  // Box can contain any number of views
  return YES;
}

- (NSRect) computeRectForViews: (NSArray *)views
{
  if ([views count] == 0) {
    return NSZeroRect;
  }
  
  NSView *contentView = self;
  
  // Step 1: Determine the position and size of the new container view
  NSRect newViewRect = [self _computeContainerRectForViews: views];
  
  // Step 2: Prepare views for grouping (deactivate editors, etc.)
  NSMutableArray *preparedViews = [self _prepareViewsForGrouping: views];
  
  // Step 3: Calculate and set positions of subviews relative to container
  [contentView _positionSubviewsInContainer: preparedViews 
                              containerRect: newViewRect];
  
  // Step 4: Add processed views to content view
  NSEnumerator *viewEnum = [preparedViews objectEnumerator];
  NSView *subview = nil;
  while ((subview = [viewEnum nextObject]) != nil)
    {
      [contentView addSubview: subview];
    }

  return newViewRect;
}

- (NSArray *) orderSelectionForViews: (NSArray *)selection
{
  return [selection copy];
}

- (void) addViews: (NSArray *)subviews
{
  // Add back into the main view...
  NSEnumerator *en = [subviews objectEnumerator];
  id v = nil;
  while ((v = [en nextObject]) != nil)
    {
      [self addSubview: v];
    }
}

@end

/*
  - (void) groupSelectionInScrollView
{
  NSEnumerator *enumerator = nil;
  NSMutableArray *viewsToGroup = [NSMutableArray array];
  NSMutableArray *editorsToClose = [NSMutableArray array];
  NSView *contentView = nil;
  NSScrollView *scrollView = nil;
  NSRect unionRect = NSZeroRect;
  GormViewEditor *editor = nil;
  NSView *parentView = nil;

  if ([selection count] < 1)
    {
      return;
    }
  
  // Collect views and compute union rect in parent coordinates
  enumerator = [selection objectEnumerator];
  GormViewEditor *subviewEditor = nil;
  while ((subviewEditor = [enumerator nextObject]) != nil)
    {
      NSView *childView = [subviewEditor editedObject];

      if (parentView == nil)
        {
          parentView = [childView superview];
        }
      else if (parentView != [childView superview])
        {
          return;
        }

      unionRect = NSUnionRect(unionRect, [childView frame]);
      [viewsToGroup addObject: childView];
      [editorsToClose addObject: subviewEditor];
      [subviewEditor deactivate];
    }

  // Create the scroll view and a content view sized to the union rect
  scrollView = [[NSScrollView alloc] initWithFrame: unionRect];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];

  contentView = [[NSView alloc] initWithFrame:
                 NSMakeRect(0, 0, unionRect.size.width, unionRect.size.height)];
  [scrollView setDocumentView: contentView];

  [document attachObject: scrollView
                toParent: _editedObject];
  [parentView addSubview: scrollView];

  // Move grouped views into the scroll view's document view
  for (NSView *childView in viewsToGroup)
    {
      NSPoint origin = [childView frame].origin;

      [childView removeFromSuperview];
      [contentView addSubview: childView];

      origin.x -= unionRect.origin.x;
      origin.y -= unionRect.origin.y;
      [childView setFrameOrigin: origin];

      [document attachObject: childView
                    toParent: scrollView];
    }

  // Close the editors for the moved views
  for (id editorToClose in editorsToClose)
    {
      [editorToClose close];
    }
  
  editor = (GormViewEditor *)[document editorForObject: scrollView
                                             inEditor: self
                                               create: YES];
  
  [self selectObjects: [NSArray arrayWithObject: editor]];
}
*/
