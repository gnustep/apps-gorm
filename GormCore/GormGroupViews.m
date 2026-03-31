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

#import "GormGroupViews.h"
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
                  isVertical: (BOOL)isVertical
{
  NSMutableArray *array = [subviews mutableCopy];
  NSArray *result = [array sortedArrayUsingFunction: _sortViews
                                            context: &isVertical];
  [array release];
  return result;
}

- (BOOL) shouldBeVertical: (NSArray *)subviews
{
  BOOL vertical = NO;
  NSEnumerator *enumerator = [subviews objectEnumerator];
  id subview = nil;

  NSRect prevRect = NSZeroRect;
  NSRect currRect = NSZeroRect;

  NSInteger count = 0;

  // Iterate over the list of views to determine orientation
  while ((subview = [enumerator nextObject]) != nil)
    {
      currRect = [subview frame];

      if (!NSEqualRects(prevRect, NSZeroRect))
        {
          CGFloat x1 = prevRect.origin.x;
          CGFloat x2 = currRect.origin.x;
          CGFloat y1 = prevRect.origin.y;
          CGFloat y2 = currRect.origin.y;
          CGFloat h1 = prevRect.size.height;
          CGFloat w1 = prevRect.size.width;

          // Check for horizontal alignment (views are side by side)
          if ((x1 < x2 || x1 > x2) && 
              ((y2 >= y1 && y2 <= (y1 + h1)) || 
               (y2 <= y1 && y2 >= (y1 - h1))))
            { 
              count++;
            }

          // Check for vertical alignment (views are stacked)
          if ((y1 < y2 || y1 > y2) && 
              ((x2 >= x1 && x2 <= (x1 + w1)) ||
               (x2 <= x1 && x2 >= (x1 - w1))))
            {
              count--;
            }
        }
      
      prevRect = currRect;
    }

  NSDebugLog(@"Vertical orientation vote count: %ld", (long)count);

  // Positive count suggests horizontal layout (vertical arrangement)
  vertical = (count >= 0);

  return vertical;
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
  NSEnumerator *en = [views objectEnumerator];
  NSRect unionRect = NSZeroRect;
  NSMutableArray *subviews = [NSMutableArray array];
  id subview = nil;

  // Calculate union of all view frames and collect processed views
  while ((subview = [en nextObject]) != nil)
    {
      unionRect = NSUnionRect(unionRect, [subview frame]);
      if ([subview respondsToSelector: @selector(deactivate)]) {
        [subview deactivate];
      }
      [subviews addObject: subview];
    }
  
  // Build frames for the subviews
  NSArray *processedViews = [self buildFramesForViews: subviews 
                                        withUnionRect: unionRect];
  
  // Add processed views to this split view
  NSEnumerator *processedEnum = [processedViews objectEnumerator];
  while ((subview = [processedEnum nextObject]) != nil)
    {
      [self addSubview: subview];
    }
  
  return unionRect;
}

- (NSArray *) orderSelectionForViews: (NSArray *)selection
{
  BOOL vertical = [self shouldBeVertical: selection];
  NSArray *array = [self sortByPosition: selection
                             isVertical: vertical];

  [self setVertical: vertical];
  return array;
}

@end

@implementation NSBox (GormGroupProtocol)

- (BOOL) validateCount: (NSUInteger)count
{
  // Box can contain any number of views
  return YES;
}

- (NSRect) computeRectForViews: (NSArray *)views
{
  NSEnumerator *en = [views objectEnumerator];
  NSRect unionRect = NSZeroRect;
  NSView *contentView = [self contentView];
  id subview = nil;

  // Calculate union rect and prepare views
  while ((subview = [en nextObject]) != nil)
    {
      unionRect = NSUnionRect(unionRect, [subview frame]); 
      if ([subview respondsToSelector: @selector(deactivate)]) {
        [subview deactivate];
      }
    }

  // Build frames and add to content view
  NSArray *processedViews = [contentView buildFramesForViews: views
                                               withUnionRect: unionRect];
  
  NSEnumerator *processedEnum = [processedViews objectEnumerator];
  while ((subview = [processedEnum nextObject]) != nil)
    {
      [contentView addSubview: subview];
    }

  return unionRect;
}

- (NSArray *) orderSelectionForViews: (NSArray *)selection
{
  BOOL vertical = [[self contentView] shouldBeVertical: selection];
  return [[self contentView] sortByPosition: selection
                                 isVertical: vertical];
}

@end
