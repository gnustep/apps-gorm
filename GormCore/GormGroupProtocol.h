/* GormGroupProtocol.h
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

#ifndef	INCLUDED_GormGroupProtocol_h
#define	INCLUDED_GormGroupProtocol_h

#import <AppKit/AppKit.h>

/**
 * Protocol for view grouping operations. This category on NSView provides
 * methods for validating view counts, computing bounding rectangles,
 * and ordering views for grouping operations.
 */
@interface NSView (GormGroupProtocol)

/**
 * Validates whether the given count of views is acceptable for this container type.
 * @param count The number of views to be grouped
 * @return YES if the count is valid for this container type, NO otherwise
 */
- (BOOL) validateCount: (NSUInteger)count;

/**
 * Computes the bounding rectangle that encompasses all the given views
 * and configures them for inclusion in this container.
 * @param subviews Array of views to be grouped
 * @return The bounding rectangle containing all views
 */
- (NSRect) computeRectForViews: (NSArray *)subviews;

/**
 * Orders the selection of views according to their spatial arrangement
 * and the container's preferred layout.
 * @param subviews Array of views to be ordered
 * @return Array of views in the proper order for grouping
 */
- (NSArray *) orderSelectionForViews: (NSArray *)subviews;

@end

#endif
