/* GormWindow.h

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/
#ifndef	INCLUDED_GormNSWindow_h
#define	INCLUDED_GormNSWindow_h

#include <AppKit/AppKit.h>

@interface GormNSWindow : NSWindow
{
  unsigned _gormStyleMask;
  BOOL     _gormReleasedWhenClosed;
  NSUInteger autoPositionMask;
}
/**
 * Sets the style mask tracked by Gorm for this window, used when serializing
 * and restoring window attributes in the editor.
 */
- (void) _setStyleMask: (unsigned int)newStyleMask;
/**
 * Returns the style mask tracked by Gorm for this window.
 */
- (unsigned int) _styleMask;
/**
 * Sets whether the window is released when closed in the running application.
 */
- (void) _setReleasedWhenClosed: (BOOL) flag;
/**
 * Returns YES if the window is released when closed; NO otherwise.
 */
- (BOOL) _isReleasedWhenClosed;
/**
 * Returns the bitmask controlling automatic positioning behavior when the
 * window opens.
 */
- (unsigned int) autoPositionMask;
/**
 * Sets the bitmask controlling automatic positioning behavior when the window
 * opens.
 */
- (void) setAutoPositionMask: (unsigned int)mask;
@end

#endif
