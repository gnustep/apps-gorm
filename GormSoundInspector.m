/** <title>GormSoundInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: September 2002

   This file is part of GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

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
#include "GormSoundInspector.h"
#include "GormPrivate.h"
#include "GormClassManager.h"
#include "GormDocument.h"
#include "GormPrivate.h"

@implementation GormSoundInspector
+ (void) initialize
{
  if (self == [GormSoundInspector class])
    {
      // TBD
    }
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      // initialize all member variables...
      // none...

      // load the gui...
      if (![NSBundle loadNibNamed: @"GormSoundInspector"
		     owner: self])
	{
	  NSLog(@"Could not open gorm GormSoundInspector");
	  return nil;
	}
      else
	{
	  [[NSNotificationCenter defaultCenter] 
	    addObserver: self
	    selector: @selector(handleNotification:)
	    name: IBSelectionChangedNotification
	    object: nil];
	}
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_currentSound);
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (void) handleNotification: (NSNotification*)aNotification
{
  id selection = [[aNotification object] selection];
  id sndobject = nil;

  // get the sound object...
  if(selection != nil)
    {
      if([selection count] > 0)
	{
	  sndobject = [selection objectAtIndex: 0];
	}
    }

  // if its not nil, load it...
  if(sndobject != nil)
    {
      if([sndobject isKindOfClass: [GormSound class]])
	{
	  NSDebugLog(@"Sound inspector notified: %@",sndobject);
	  RELEASE(_currentSound);
	  _currentSound = [[NSSound alloc] initWithContentsOfFile: [sndobject soundPath]
					   byReference: YES];
	  RETAIN(_currentSound);
	  NSDebugLog(@"Loaded sound");
	}
    }
}

- (void) stop: (id)sender
{
  NSDebugLog(@"Stop");
  [_currentSound stop];
}

- (void) play: (id)sender
{
  NSDebugLog(@"Play");
  [_currentSound play];
}

- (void) pause: (id)sender
{
  NSDebugLog(@"Pause");
  [_currentSound pause];
}

- (void) record: (id)sender
{
  NSDebugLog(@"Record");
  // [_currentSound record];
}
@end
