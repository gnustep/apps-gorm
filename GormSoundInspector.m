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
#include "Gorm.h"

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
}

- (void) handleNotification: (NSNotification*)aNotification
{
  id sndobject = [[[aNotification object] selection] objectAtIndex: 0];

  if([sndobject isKindOfClass: [GormSound class]])
    {
      NSLog(@"Sound inspector notified: %@",sndobject);
      RELEASE(_currentSound);
      _currentSound = [[NSSound alloc] initWithContentsOfFile: [sndobject soundPath]
				       byReference: YES];
      RETAIN(_currentSound);
      NSLog(@"Loaded sound");
    }
}

- (void) awakeFromNib
{
  NSLog(@"Sound inspector is awake");
}

- (void) stop: (id)sender
{
  NSLog(@"Stop");
  [_currentSound stop];
}

- (void) play: (id)sender
{
  NSLog(@"Play");
  [_currentSound play];
}

- (void) pause: (id)sender
{
  NSLog(@"Pause");
  [_currentSound pause];
}

- (void) record: (id)sender
{
  NSLog(@"Record");
  // [_currentSound record];
}
@end

