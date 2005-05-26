/* IBInspectorManager.m
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2004
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <InterfaceBuilder/IBInspectorManager.h>

static IBInspectorManager *_sharedInspectorManager = nil;

/**
 * Notifications to be sent prior to the action described.
 */ 
NSString *IBWillInspectObjectNotification = 
    @"IBWillInspectObjectNotification";
NSString *IBWillInspectWithModeNotification = 
    @"IBWillInspectWithModeNotification"; 

@implementation IBInspectorManager

/**
 * Create a shared instance of the class for the application. 
 * If a subclass of IBInspectorManager uses this message it becomes
 * the shraredInspectorManager.
 */
+ (IBInspectorManager *) sharedInspectorManager
{
  if(_sharedInspectorManager == nil)
    {
      _sharedInspectorManager = [[self alloc] init];
    }
  return _sharedInspectorManager;
}

- (id) init
{
  if(_sharedInspectorManager == nil)
    {
      if((self = [super init]) != nil)
	{
	  // set the shared instance...
	  _sharedInspectorManager = self;
	}
    }
  else
    {
      RELEASE(self);
      self = _sharedInspectorManager;
    }

  return self;
}

/**
 * Add an inspector for a given mode.  This allows the addition
 * of inspectors for different aspects of the same object.
 */
- (void) addInspectorModeWithIdentifier: (NSString *)ident
                              forObject: (id)obj
                         localizedLabel: (NSString *)label
                     inspectorClassName: (NSString *)className
                               ordering: (float)ord
{
}

/**
 * Position in the inspector list that the "mode inspector"
 * appears.
 */
- (unsigned int) indexOfModeWithIdentifier: (NSString *)ident
{
  return 0;
}
@end
