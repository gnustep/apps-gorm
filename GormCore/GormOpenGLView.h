/* GormOpenGLView.h - Demo view for show when displaying a NSOpenGLView during
 *                    testing only.
 *
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2005
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

#ifndef INCLUDED_GormOpenGLView_h
#define INCLUDED_GormOpenGLView_h

#include <AppKit/AppKit.h>

@class NSTimer;

/**
 * GormOpenGLView provides a demo view that displays a rotating triangle
 * when an NSOpenGLView is being tested in the interface builder. This serves
 * as a visual placeholder during testing mode only.
 */
@interface GormOpenGLView : NSView
{
  float rtri;
  NSTimer *timer;
}
@end

#endif
