/* GormPlacementInfo.h
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
#ifndef	INCLUDED_GormPlacementInfo_h
#define	INCLUDED_GormPlacementInfo_h

#include <Foundation/Foundation.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

@class NSView, NSMutableArray;

/**
 * GormPlacementInfo stores state used when placing and resizing views. It
 * tracks hint rectangles and recent frames to compute guideline snaps.
 */
@interface GormPlacementInfo : NSObject
{
@public
  NSView *resizingIn;
  NSRect oldRect;
  BOOL firstPass;
  BOOL hintInitialized;
  NSMutableArray *leftHints;
  NSMutableArray *rightHints;
  NSMutableArray *topHints;
  NSMutableArray *bottomHints;
  NSRect lastLeftRect;
  NSRect lastRightRect;
  NSRect lastTopRect;
  NSRect lastBottomRect;
  NSRect hintFrame;
  NSRect lastFrame;
  IBKnobPosition knob;
}
@end

typedef enum _GormHintBorder
{
  Top, Bottom, Left, Right
} GormHintBorder;

/**
 * GormPlacementHint describes a single alignment hint along a border with a
 * valid range and frame, used to compute snapping while dragging/resizing.
 */
@interface GormPlacementHint : NSObject
{
  GormHintBorder _border;
  float _position;
  float _start;
  float _end;
  NSRect _frame;
}
/**
 * Initializes and returns a new instance.
 */
- (id) initWithBorder: (GormHintBorder) border
	     position: (float) position
	validityStart: (float) start
	  validityEnd: (float) end
		frame: (NSRect) frame;
/**
 * Compute the hint rectangle using the given half-distance value.
 */
- (NSRect) rectWithHalfDistance: (int) halfDistance;
/**
 * Return the absolute distance from this hint to the specified frame.
 */
- (int) distanceToFrame: (NSRect) frame;
/**
 * The primary position of this hint along its border.
 */
- (float) position;
/**
 * The start of the valid range for this hint.
 */
- (float) start;
/**
 * The end of the valid range for this hint.
 */
- (float) end;
/**
 * The frame rectangle associated with this hint.
 */
- (NSRect) frame;
/**
 * The border (top, bottom, left, right) where this hint applies.
 */
- (GormHintBorder) border;
@end

#endif
