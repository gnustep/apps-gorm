/* IBViewAdditions.h
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
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

#ifndef INCLUDED_IBVIEWADDITIONS_H
#define INCLUDED_IBVIEWADDITIONS_H

#include <InterfaceBuilder/IBDefines.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSView.h>
#include <AppKit/NSCell.h>

// forward references
@class NSColor;

@interface NSView (IBViewAdditions)
- (BOOL) acceptsColor: (NSColor*)color atPoint: (NSPoint)point;
- (BOOL) allowsAltDragging;
- (void) depositColor: (NSColor*)color atPoint: (NSPoint)point;
- (NSSize) maximumSizeFromKnobPosition: (IBKnobPosition)knobPosition;
- (NSSize) minimumSizeFromKnobPosition: (IBKnobPosition)position;
- (void) placeView: (NSRect)newFrame;
@end

@interface NSCell (IBCellAdditions)
- (void) cellWillAltDragWithSize: (NSSize)size;
- (NSSize) maximumSizeForCellSize: (NSSize)size 
                     knobPosition: (IBKnobPosition)position;
- (NSSize) minimumSizeForCellSize: (NSSize)size 
                     knobPosition: (IBKnobPosition)position;
@end

#endif
