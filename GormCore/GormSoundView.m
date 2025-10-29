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

/* All rights reserved */

#include <AppKit/AppKit.h>
#include <AppKit/PSOperators.h>

#include "GormSoundView.h"

// add a data method to the NSSound class...
@interface NSSound (SoundView)
- (NSData *)data;
@end

@implementation NSSound (SoundView)
- (NSData *)data
{
  return _data;
}
@end

@implementation GormSoundView

- (void)setSamples:(short *)newSamples
       sampleCount:(NSUInteger)count
        sampleRate:(float)rate
{
  if (_samples)
    {
      free(_samples);
    }

  _samples = malloc(sizeof(short) * count);
  if (_samples && newSamples)
    {
      memcpy(_samples, newSamples, sizeof(short) * count);
    }

  _sampleCount = count;
  _sampleRate = rate;

  [self setNeedsDisplay:YES];
}

- (BOOL)loadFromSound:(NSSound *)sound
{
  NSData *soundData = [sound valueForKey:@"_data"];
  if (!soundData)
    {
      return NO;
    }

  const void *bytes = [soundData bytes];
  NSUInteger length = [soundData length];

  if (length < 44)
    {
      return NO;
    }

  const unsigned char *ptr = (const unsigned char *)bytes;
  if (memcmp(ptr, "RIFF", 4) != 0
      || memcmp(ptr + 8, "WAVE", 4) != 0)
    {
      return NO;
    }

  int offset = 12;
  int fmtFound = 0;
  int dataFound = 0;
  unsigned short bitsPerSample = 0;
  unsigned short numChannels = 0;
  unsigned int sampleRateRead = 0;
  unsigned int dataSize = 0;
  short *pcmStart = NULL;

  while (offset + 8 <= length)
    {
      char chunkId[5] = {0};
      memcpy(chunkId, ptr + offset, 4);
      unsigned int chunkSize = *(unsigned int *)(ptr + offset + 4);

      if (memcmp(chunkId, "fmt ", 4) == 0)
        {
          if (chunkSize < 16)
            {
              return NO;
            }

          numChannels = *(unsigned short *)(ptr + offset + 10);
          sampleRateRead = *(unsigned int *)(ptr + offset + 12);
          bitsPerSample = *(unsigned short *)(ptr + offset + 22);
          fmtFound = 1;
        }
      else if (memcmp(chunkId, "data", 4) == 0)
        {
          dataSize = chunkSize;
          pcmStart = (short *)(ptr + offset + 8);
          dataFound = 1;
          break;
        }

      offset += 8 + chunkSize;
    }

  if (!fmtFound
      || !dataFound
      || bitsPerSample != 16
      || numChannels != 1)
    {
      return NO;
    }

  NSUInteger count = dataSize / 2;
  short *copy = malloc(dataSize);
  if (!copy)
    {
      return NO;
    }
  memcpy(copy, pcmStart, dataSize);

  [self setSamples:copy sampleCount:count
	sampleRate:(float)sampleRateRead];
  free(copy);

  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSRect bounds = [self bounds];
  [[NSColor blackColor] set];
  NSRectFill(bounds);

  if (!_samples || _sampleCount == 0)
    {
      return;
    }

  [[NSColor greenColor] set];

  NSBezierPath *path = [NSBezierPath bezierPath];

  float midY = bounds.size.height / 2.0;
  float xScale = bounds.size.width / (float)_sampleCount;
  float yScale = midY / 32768.0;

  [path moveToPoint:NSMakePoint(0, midY)];

  NSUInteger i;
  for (i = 0; i < _sampleCount; ++i)
    {
      float x = (float)i * xScale;
      float y = midY + _samples[i] * yScale;
      [path lineToPoint:NSMakePoint(x, y)];
    }

  [path stroke];
}

- (void)dealloc
{
  if (_samples)
    {
      free(_samples);
    }

  [super dealloc];
}

- (void) setSound: (NSSound *)sound
{
  ASSIGN(_sound, sound);
  [self loadFromSound: sound];
  [self setNeedsDisplay: YES];
}

- (NSSound *)sound
{
  return _sound;
}

@end
