/* GormSound.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	Dec 2004
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

#include <Foundation/NSString.h>
#include <AppKit/NSSound.h>
#include "GormSound.h"

// sound proxy object...
@implementation GormSound
+ (GormSound*) soundForPath: (NSString *)aPath
{
  return AUTORELEASE([[GormSound alloc] initWithPath: aPath]);
}

- (id) initWithPath: (NSString *)aPath
{
  NSString *aName = [[aPath lastPathComponent] stringByDeletingPathExtension];
  if((self = [self initWithName: aName path: aPath]) == nil)
    {
      RELEASE(self);
    }
  return self;
}

- (id) initWithName: (NSString *)aName
	       path: (NSString *)aPath
{
  NSSound *sound = [[NSSound alloc] initWithContentsOfFile: aPath
		   byReference: YES];
  [super init];
  ASSIGN(name, aName);
  ASSIGN(path, aPath);

  //#warning "we want to store the sound somewhere"
  [(NSSound *)sound setName: aName];
  isSystemSound = NO;
  isInWrapper = NO;
  return self;
}

- (void) setSoundName: (NSString *)aName
{
  ASSIGN(name, aName);
}

- (NSString *) soundName
{
  return name;
}

- (void) setSoundPath: (NSString *)aPath
{
  ASSIGN(path, aPath);
}

- (NSString *) soundPath
{
  return path;
}

- (void) setSystemSound: (BOOL)flag
{
  isSystemSound = flag;
}

- (BOOL) isSystemSound
{
  return isSystemSound;
}

- (void) setInWrapper: (BOOL)flag
{
  isInWrapper = flag;
}

- (BOOL) isInWrapper
{
  return isInWrapper;
}

- (NSString *)inspectorClassName
{
  return @"GormSoundInspector";
}

- (NSString*) classInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) connectInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormNotApplicableInspector";
}
@end
