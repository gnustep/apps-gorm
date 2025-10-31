/** <title>GormScrollViewAttributesInspector</title>

   <abstract>allow user to edit attributes of a scroll view</abstract>

   Copyright (C) 2003 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: June 2003

   This file is part of GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

/* All Rights reserved */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

@interface GormScrollViewAttributesInspector : IBInspector
{
  id pageContext;
  id lineAmount;
  id color;
  id verticalScroll;
  id horizontalScroll;
  id verticalRuler;
  id horizontalRuler;
  id borderMatrix;
}
/**
 * Updates the scroll view's color-related attribute based on the user's
 * selection (such as background color or scroller tint).
 */
- (void) colorSelected: (id)sender;
/**
 * Toggles or updates vertical scrolling settings for the selected scroll view.
 */
- (void) verticalSelected: (id)sender;
/**
 * Toggles or updates horizontal scrolling settings for the selected scroll view.
 */
- (void) horizontalSelected: (id)sender;
/**
 * Toggles the visibility of the vertical ruler for the selected scroll view.
 */
- (void) verticalRuler: (id)sender;
/**
 * Toggles the visibility of the horizontal ruler for the selected scroll view.
 */
- (void) horizontalRuler: (id)sender;
/**
 * Changes the border style of the selected scroll view.
 */
- (void) borderSelected: (id)sender;
@end
