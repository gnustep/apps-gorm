/* GormClassManager.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

#include "GormPrivate.h"

@implementation GormClassManager

- (NSArray*) allActionsForObject: (NSObject*)obj
{
  NSString	*className;
  NSArray	*actions;
  Class		theClass = [obj class];

  if (theClass == [GormFirstResponder class])
    {
      return nil;
    }

  if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }
  if (className == nil)
    {
      NSLog(@"attempt to get actions for non-existent class");
      return nil;
    }

  actions = [self allActionsForClassNamed: className];
  while (actions == nil && (theClass = class_get_super_class(theClass)) != nil
    && theClass != [NSObject class])
    {
      className = NSStringFromClass(theClass);
      actions = [self allActionsForClassNamed: className];
    }
  return actions;
}

- (NSArray*) allActionsForClassNamed: (NSString*)className
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];

  if (info != nil)
    {
      NSMutableArray	*allActions = [info objectForKey: @"AllActions"];

      if (allActions == nil)
	{
	  NSString	*superName = [info objectForKey: @"Super"];
	  NSArray	*actions = [info objectForKey: @"Actions"];
	  NSArray	*superActions;

	  if (superName == nil)
	    {
	      superActions = nil;
	    }
	  else
	    {
	      superActions = [self allActionsForClassNamed: superName];
	    }

	  if (superActions == nil)
	    {
	      if (actions == nil)
		{
		  allActions = [NSMutableArray new];
		}
	      else
		{
		  allActions = [actions mutableCopy];
		}
	    }
	  else
	    {
	      allActions = [superActions mutableCopy];
	      if (actions != nil)
		{
		  NSEnumerator	*enumerator = [actions objectEnumerator];
		  NSString	*actionName;

		  while ((actionName = [enumerator nextObject]) != nil)
		    {
		      if ([allActions containsObject: actionName] == NO)
			{
			  [allActions addObject: actionName];
			}
		    }
		  [allActions sortUsingSelector: @selector(compare:)];
		}
	    }
	  [info setObject: allActions forKey: @"AllActions"];
	  RELEASE(allActions);
	}
      return AUTORELEASE([allActions copy]);
    }
  return nil;
}

- (NSArray*) allOutletsForObject: (NSObject*)obj
{
  NSString	*className;
  NSArray	*outlets;
  Class		theClass = [obj class];

  if (theClass == [GormFirstResponder class])
    {
      return nil;
    }

  if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }

  if (className == nil)
    {
      NSLog(@"attempt to get outlets for non-existent class");
      return nil;
    }

  outlets = [self allOutletsForClassNamed: className];
  while (outlets == nil && (theClass = class_get_super_class(theClass)) != nil
    && theClass != [NSObject class])
    {
      className = NSStringFromClass(theClass);
      outlets = [self allOutletsForClassNamed: className];
    }
  return outlets;
}

- (NSArray*) allOutletsForClassNamed: (NSString*)className;
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];

  if (info != nil)
    {
      NSMutableArray	*allOutlets = [info objectForKey: @"AllOutlets"];

      if (allOutlets == nil)
	{
	  NSString	*superName = [info objectForKey: @"Super"];
	  NSArray	*outlets = [info objectForKey: @"Outlets"];
	  NSArray	*superOutlets;

	  if (superName == nil)
	    {
	      superOutlets = nil;
	    }
	  else
	    {
	      superOutlets = [self allOutletsForClassNamed: superName];
	    }

	  if (superOutlets == nil)
	    {
	      if (outlets == nil)
		{
		  allOutlets = [NSMutableArray new];
		}
	      else
		{
		  allOutlets = [outlets mutableCopy];
		}
	    }
	  else
	    {
	      allOutlets = [superOutlets mutableCopy];
	      if (outlets != nil)
		{
		  NSEnumerator	*enumerator = [outlets objectEnumerator];
		  NSString	*outletName;

		  while ((outletName = [enumerator nextObject]) != nil)
		    {
		      if ([allOutlets containsObject: outletName] == NO)
			{
			  [allOutlets addObject: outletName];
			}
		    }
		  [allOutlets sortUsingSelector: @selector(compare:)];
		}
	    }
	  [info setObject: allOutlets forKey: @"AllOutlets"];
	  RELEASE(allOutlets);
	}
      return AUTORELEASE([allOutlets copy]);
    }
  return nil;
}

- (void) dealloc
{
  RELEASE(classInformation);
  [super dealloc];
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSBundle			*bundle = [NSBundle mainBundle];
      NSString			*path;
      NSDictionary		*dict;
      NSEnumerator		*enumerator;
      NSString			*key;

      path = [bundle pathForResource: @"ClassInformation" ofType: @"plist"];
      if (path == nil)
	{
	  NSLog(@"ClassInformation.plist missing from resources");
	  dict = nil;
	}
      else
	{
	  dict = [NSDictionary dictionaryWithContentsOfFile: path];
	}

      /*
       * Convert property-list data into a mutable structure.
       */
      classInformation = [NSMutableDictionary new]; 
      enumerator = [dict keyEnumerator];
      while ((key = [enumerator nextObject]) != nil)
	{
	  NSDictionary		*classInfo = [dict objectForKey: key];
	  NSMutableDictionary	*newInfo;
	  id			obj;

	  newInfo = [NSMutableDictionary new];
	  [classInformation setObject: newInfo forKey: key];
	  RELEASE(newInfo);

	  obj = [classInfo objectForKey: @"Super"];
	  if (obj != nil)
	    {
	      [newInfo setObject: obj forKey: @"Super"];
	    }
	  obj = [classInfo objectForKey: @"Outlets"];
	  if (obj != nil)
	    {
	      obj = [obj mutableCopy];
	      [obj sortUsingSelector: @selector(compare:)];
	      [newInfo setObject: obj forKey: @"Outlets"];
	      RELEASE(obj);
	    }
	  obj = [classInfo objectForKey: @"Actions"];
	  if (obj != nil)
	    {
	      obj = [obj mutableCopy];
	      [obj sortUsingSelector: @selector(compare:)];
	      [newInfo setObject: obj forKey: @"Actions"];
	      RELEASE(obj);
	    }
	}
    }
  return self;
}

@end

