/** <title>GormSoundInspector</title>

   <abstract>allow user to inspect sound files in Gorm</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: September 2002

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
   31 Milk St # 960789 Boston, MA 02196 USA
*/
#ifndef	INCLUDED_GormSoundInspector_h
#define	INCLUDED_GormSoundInspector_h

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

@class GormClassManager;
@class GormSoundView;

/**
 * GormSoundInspector lets the user preview and record sound resources within
 * Gorm. It hosts playback controls wired to the document's selected sound.
 */
GS_EXPORT_CLASS
@interface GormSoundInspector : IBInspector
{
  GormSoundView *soundView;
}
/**
 * Stop playback or recording.
 */
- (void) stop: (id)sender;
/**
 * Start or resume playback.
 */
- (void) play: (id)sender;
/**
 * Pause playback.
 */
- (void) pause: (id)sender;
/**
 * Begin recording from the configured input.
 */
- (void) record: (id)sender;
@end

#endif
