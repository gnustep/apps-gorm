/** <title>GormSoundView</title>

   <abstract>Visualizes a sound.<abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: May 2004

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

#include <Cocoa/Cocoa.h>

@interface GormSoundView : NSView
{
  short *_samples;
  NSUInteger _sampleCount;
  float _sampleRate;
  NSSound *_sound;
}

/**
 * Supplies PCM sample data to visualize. The samples buffer is not retained;
 * callers are responsible for its lifetime.
 */
- (void)setSamples:(short *)newSamples
       sampleCount:(NSUInteger)count
        sampleRate:(float)rate;

/**
 * Loads sample data from the specified NSSound and prepares it for display.
 * Returns YES on success; NO otherwise.
 */
- (BOOL)loadFromSound:(NSSound *)sound;

/**
 * Sets the NSSound backing this view. May trigger a redraw of the waveform.
 */
- (void) setSound: (NSSound *)sound;

/**
 * Returns the NSSound currently visualized by the view.
 */
- (NSSound *) sound;

@end
