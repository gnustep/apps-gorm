/* GormGroupViews.h
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

#ifndef	INCLUDED_GormGroupViews_h
#define	INCLUDED_GormGroupViews_h

#import <AppKit/AppKit.h>
#import "GormGroupProtocol.h"

@class GormViewEditor;

/**
 * Category on NSView providing utility methods for view grouping operations.
 * These methods support determining layout orientation and sorting views.
 */
@interface NSView (GormGroupUtils)

/**
 * Determines whether views should be arranged vertically based on their positions.
 * The <var>subviews</var> argument is an array of GormViewEditor objects to
 * analyze. Returns YES if views should be arranged vertically, NO for
 * horizontal.
 */
- (BOOL) shouldBeVertical: (NSArray *)subviews;

/**
 * Sorts views by their position according to the specified orientation.
 * The <var>subviews</var> argument is an array of GormViewEditor objects to
 * sort. The <var>isVertical</var> argument is YES to sort by horizontal
 * position, NO to sort by vertical position. Returns the sorted array of
 * views.
 */
- (NSArray *) sortByPosition: (NSArray *)subviews 
                  isVertical: (BOOL *)isVertical;

/**
 * Adjusts view frames relative to a union rectangle and content origin.
 * The <var>views</var> argument is an array of NSView objects to adjust.
 * The <var>unionRect</var> argument is the bounding rectangle to use as the
 * reference. Returns an array of adjusted views.
 */
- (NSArray *) buildFramesForViews: (NSArray *)views
                    withUnionRect: (NSRect)unionRect;

/**
 * Computes the union rectangle that encloses the supplied views.
 */
- (NSRect) _computeContainerRectForViews: (NSArray *)views;

/**
 * Returns a mutable list of views prepared for grouping operations.
 */
- (NSMutableArray *) _prepareViewsForGrouping: (NSArray *)views;

/**
 * Repositions views into the coordinate space of the supplied container rect.
 */
- (void) _positionSubviewsInContainer: (NSArray *)views
                        containerRect: (NSRect)containerRect;

@end

#endif
