/* GormClassManager.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2002
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
#include "GormCustomView.h"

NSString *IBClassNameChangedNotification = @"IBClassNameChangedNotification";

@interface	GormClassManager (Private)
- (NSMutableDictionary*) classInfoForClassName: (NSString*)className;
- (NSMutableDictionary*) classInfoForObject: (id)anObject;
@end

@implementation GormClassManager

- (void) addAction: (NSString*)anAction forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraActions = [info objectForKey: @"ExtraActions"];
  NSMutableArray	*allActions = [self allActionsForObject: anObject];

  if ([extraActions containsObject: anAction] == YES)
    {
      return;	/* Can't add action twice. */
    }
  if (extraActions == nil)
    {
      extraActions = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraActions forKey: @"ExtraActions"];
      RELEASE(extraActions);
    }
  [extraActions addObject: anAction];
  if ([allActions containsObject: anAction] == NO)
    {
      [[info objectForKey: @"AllActions"] addObject: anAction];
    }
}

- (NSString*) addClassWithSuperClassName: (NSString*)name
{
  if ([name isEqualToString: @"NSObject"]
    || [classInformation objectForKey: name] != nil)
    {
      NSMutableDictionary	*classInfo;
      NSMutableArray		*outlets;
      NSMutableArray		*actions;
      NSString			*newClassName;
      int			i;

      classInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
      outlets = [[NSMutableArray alloc] initWithCapacity: 0];
      actions = [[NSMutableArray alloc] initWithCapacity: 0];
      newClassName = @"NewClass";
      i = 1;

      [classInfo setObject: outlets forKey: @"Outlets"];
      RELEASE(outlets);
      [classInfo setObject: actions forKey: @"Actions"];
      RELEASE(actions);
      [classInfo setObject: name forKey: @"Super"];

      while([classInformation objectForKey: newClassName] != nil)
	{
	  newClassName = [newClassName stringByAppendingString:
	    [NSString stringWithFormat: @"%d", i++]];

	}
      [classInformation setObject: classInfo forKey: newClassName];
      [customClasses addObject: newClassName];
      RELEASE(classInfo);

      return newClassName;
    }
  return @"";
}

- (NSString *) addNewActionToClassNamed: (NSString *)name
{
  NSDictionary *classInfo = [classInformation objectForKey: name];
  NSArray *array = [classInfo objectForKey: @"Actions"];
  NSArray *extra = [classInfo objectForKey: @"ExtraActions"];
  NSMutableArray *combined = [NSMutableArray arrayWithArray: array];
  NSString *new = @"newAction", *search = [new stringByAppendingString: @":"];
  int i = 1;
  [combined addObjectsFromArray: extra];
  while([combined containsObject: search])
    {
      new = [new stringByAppendingString: [NSString stringWithFormat: @"%d", i++]];
      search = [new stringByAppendingString: @":"];
    }

  [self addAction: search forClassNamed: name];
  return search;
}

- (NSString *) addNewOutletToClassNamed: (NSString *)name
{
  NSDictionary *classInfo = [classInformation objectForKey: name];
  NSArray *array = [classInfo objectForKey: @"Outlets"];
  NSArray *extra = [classInfo objectForKey: @"ExtraOutlets"];
  NSMutableArray *combined = [NSMutableArray arrayWithArray: array];
  NSString *new = @"newOutlet";
  int i = 1;

  [combined addObjectsFromArray: extra];
  while([combined containsObject: new])
    {
      new = [new stringByAppendingString: [NSString stringWithFormat: @"%d", i++]];
    }

  [self addOutlet: new forClassNamed: name];
  return new;
}

- (BOOL) addClassNamed: (NSString*)className
   withSuperClassNamed: (NSString*)superClassName
	   withActions: (NSArray*)actions
	   withOutlets: (NSArray*)outlets
{
  BOOL result = NO;

  if ([superClassName isEqualToString: @"NSObject"]
    || [classInformation objectForKey: superClassName] != nil)
    {
      NSMutableDictionary	*classInfo;

      if(![classInformation objectForKey: className])
	{
	  classInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
	  
	  [classInfo setObject: outlets forKey: @"Outlets"];
	  [classInfo setObject: actions forKey: @"Actions"];
	  [classInfo setObject: superClassName forKey: @"Super"];
	  [classInformation setObject: classInfo forKey: className];
	  [customClasses addObject: className];
	  RELEASE(classInfo);
	  result = YES;
	}
      else
	{
	  NSLog(@"Class already exists");
	  result = NO;
	}
    }

  return result;
}

- (void) addOutlet: (NSString*)anOutlet forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSArray		*allOutlets = [self allOutletsForObject: anObject];

  if ([allOutlets containsObject: anOutlet] == YES)
    {
      return;	/* Can't add outlet with same name. */
    }
  if (extraOutlets == nil)
    {
      extraOutlets = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraOutlets forKey: @"ExtraOutlets"];
      RELEASE(extraOutlets);
    }
  [extraOutlets addObject: anOutlet];
  [[info objectForKey: @"AllOutlets"] addObject: anOutlet];
}

- (void) addAction: (NSString *)anAction forClassNamed: (NSString *)className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraActions = [info objectForKey: @"ExtraActions"];
  NSArray *allActions = [self allActionsForClassNamed: className];

  if([allActions containsObject: anAction])
    {
      return;
    }
  if(extraActions == nil)
    {
      extraActions = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraActions forKey: @"ExtraActions"];
      RELEASE(extraActions);
    }

  [extraActions addObject: anAction];
  [[info objectForKey: @"AllActions"] insertObject: anAction atIndex: 0];
}

- (void) addOutlet: (NSString *)anOutlet forClassNamed: (NSString *)className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSArray *allOutlets = [self allOutletsForClassNamed: className];

  if([allOutlets containsObject: anOutlet])
    {
      return;
    }
  if(extraOutlets == nil)
    {
      extraOutlets = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraOutlets forKey: @"ExtraOutlets"];
      RELEASE(extraOutlets);
    }

  [extraOutlets addObject: anOutlet];
  [[info objectForKey: @"AllOutlets"] insertObject: anOutlet atIndex: 0];
}

- (void) replaceAction: (NSString *)oldAction withAction: (NSString *)newAction forClassNamed: className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraActions = [info objectForKey: @"ExtraActions"];
  NSMutableArray *actions = [info objectForKey: @"Actions"];
  NSMutableArray *allActions = [info objectForKey: @"AllActions"];

  if([allActions containsObject: newAction] || 
     [extraActions containsObject: newAction])
    {
      return;
    }

  if([extraActions containsObject: oldAction])
    {
      int all_index = [allActions indexOfObject: oldAction];
      int extra_index = [extraActions indexOfObject: oldAction];

      [extraActions replaceObjectAtIndex: extra_index withObject: newAction];
      [allActions replaceObjectAtIndex: all_index withObject: newAction];
    }
  else if([actions containsObject: oldAction])
    {
      int all_index = [allActions indexOfObject: oldAction];
      int actions_index = [actions indexOfObject: oldAction];

      [actions replaceObjectAtIndex: actions_index withObject: newAction];
      [allActions replaceObjectAtIndex: all_index withObject: newAction];
    }
}

- (void) replaceOutlet: (NSString *)oldOutlet withOutlet: (NSString *)newOutlet forClassNamed: className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSMutableArray *outlets = [info objectForKey: @"Outlets"];
  NSMutableArray *allOutlets = [info objectForKey: @"AllOutlets"];

  if([allOutlets containsObject: newOutlet] || 
     [extraOutlets containsObject: newOutlet])
    {
      return;
    }

  if([extraOutlets containsObject: oldOutlet])
    {
      int all_index = [allOutlets indexOfObject: oldOutlet];
      int extra_index = [extraOutlets indexOfObject: oldOutlet];

      [extraOutlets replaceObjectAtIndex: extra_index withObject: newOutlet];
      [allOutlets replaceObjectAtIndex: all_index withObject: newOutlet];
    }
  else if([outlets containsObject: oldOutlet])
    {
      int all_index = [allOutlets indexOfObject: oldOutlet];
      int outlets_index = [outlets indexOfObject: oldOutlet];

      [outlets replaceObjectAtIndex: outlets_index withObject: newOutlet];
      [allOutlets replaceObjectAtIndex: all_index withObject: newOutlet];
    }
}

- (NSArray*) allActionsForObject: (id)obj
{
  NSString	*className;
  NSArray	*actions;
  Class		 theClass = [obj class];
  NSString      *customClassName = [self customClassForObject: obj];

  if(customClassName != nil)
    {
      // if the object has been mapped to a custom class, then
      // get the information for it.
      className = customClassName;
    }
  else if (theClass == [GormFirstResponder class])
    {
      className = @"FirstResponder";
    }
  else if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else if ([obj isKindOfClass: [GSNibItem class]] == YES)
    {
      // this adds support for custom objects
      className = [obj className];
    }
  else if ([obj isKindOfClass: [GormClassProxy class]] == YES)
    {
      // this adds support for class proxies
      className = [obj className];
    }
  else if ([obj isKindOfClass: [GormCustomView class]] == YES)
    {
      // this adds support for custom views
      className = [obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }
  if (className == nil)
    {
      NSLog(@"attempt to get actions for non-existent class (%@)",	
      	[obj class]);
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

- (NSArray*) allClassNames
{
  NSArray *array = [NSArray arrayWithObject: @"NSObject"];
  return [array arrayByAddingObjectsFromArray:
    [[classInformation allKeys] sortedArrayUsingSelector: @selector(compare:)]];
}

- (NSArray*) allOutletsForObject: (id)obj
{
  NSString	*className;
  NSArray	*outlets;
  Class		theClass = [obj class];
  NSString      *customClassName = [self customClassForObject: obj];

  if(customClassName != nil)
    {
      // if the object has been mapped to a custom class, then
      // get the information for it.
      className = customClassName; 
    }
  else if (theClass == [GormFirstResponder class])
    {
      return nil;
    }
  else if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else if ([obj isKindOfClass: [GSNibItem class]] == YES)
    {
      // this adds support for custom objects
      className = [(id)obj className];
    }
  else if ([obj isKindOfClass: [GormClassProxy class]] == YES)
    {
      // this adds support for class proxies
      className = [(id)obj className];
    }
  else if ([obj isKindOfClass: [GormCustomView class]] == YES)
    {
      // this adds support for custom views
      className = [(id)obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }

  if (className == nil)
    {
      NSLog(@"attempt to get outlets for non-existent class (%@)",
      	[obj class]);
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

- (NSMutableDictionary*) classInfoForClassName: (NSString*)className
{
  NSMutableDictionary	*info;

  info = [classInformation objectForKey: className];
  if (info == nil)
    {
      Class	theClass = NSClassFromString(className);

      if (theClass != nil)
	{
	  theClass = class_get_super_class(theClass);
	  if (theClass != nil && theClass != [NSObject class])
	    {
	      NSString			*name;
	      NSMutableDictionary	*dict;

	      name = NSStringFromClass(theClass);
	      dict = [self classInfoForClassName: name];
	      if (dict != nil)
		{
		  id	o;

		  info = [[NSMutableDictionary alloc] initWithCapacity: 3];
		  [info setObject: name forKey: @"Super"];
		  o = [[self allActionsForClassNamed: name] mutableCopy];
		  [info setObject: o forKey: @"AllActions"];
		  o = [[self allOutletsForClassNamed: name] mutableCopy];
		  [info setObject: o forKey: @"AllOutlets"];
		  [classInformation setObject: info forKey: className];
		  RELEASE(info);
		}
	    }
	}
    }
  return info;
}

- (NSMutableDictionary*) classInfoForObject: (id)obj
{
  NSString		*className;
  Class			theClass = [obj class];

  if (theClass == [GormFilesOwner class])
    {
      className = [(GormFilesOwner*)obj className];
    }
  else if ([obj isKindOfClass: [GSNibItem class]] == YES)
    {
      // this adds support for custom objects
      className = [(id)obj className];
    }
  else if ([obj isKindOfClass: [GormClassProxy class]] == YES)
    {
      // this adds support for class proxies
      className = [(id)obj className];
    }
  else if ([obj isKindOfClass: [GormCustomView class]] == YES)
    {
      // this adds support for custom views
      className = [(id)obj className];
    }
  else
    {
      className = NSStringFromClass(theClass);
    }

  if (className == nil)
    {
      NSLog(@"attempt to get outlets for non-existent class (%@)",
      	[obj class]);
      return nil;
    }
  return [self classInfoForClassName: className];
}

- (void) dealloc
{
  RELEASE(classInformation);
  [super dealloc];
}

- (NSArray*) extraActionsForObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];

  return [info objectForKey: @"ExtraActions"];
}

- (NSArray*) extraOutletsForObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];

  return [info objectForKey: @"ExtraOutlets"];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSBundle			*bundle = [NSBundle mainBundle];
      NSString			*path;

      path = [bundle pathForResource: @"ClassInformation" ofType: @"plist"];
      if (path == nil)
	{
	  NSLog(@"ClassInformation.plist missing from resources");
	}
      else
	{
	  // load the classes, initialize the custom class array and map..
	  [self loadFromFile: path];
	  customClasses = RETAIN([NSMutableArray arrayWithCapacity: 1]);
	  customClassMap = RETAIN([NSMutableDictionary dictionaryWithCapacity: 10]); 
	  
	  // add first responder so that it may be edited.
	  [customClasses addObject: @"FirstResponder"];
	}
    }
  
  return self;
}

- (void) allSubclassesOf: (NSString *)superclass
      referenceClassList: (NSArray *)classList
	       intoArray: (NSMutableArray *)array
{
  NSEnumerator *cen   = [classList objectEnumerator];
  id object = nil;

  while((object = [cen nextObject]))
    {
      NSDictionary *dictForClass = [classInformation objectForKey: object];
      if([[dictForClass objectForKey: @"Super"] isEqual: superclass])
	{
	  [array addObject: object];
	  [self allSubclassesOf: object
		referenceClassList: classList
		intoArray: array];
	}
    }
}

- (NSArray *) allCustomSubclassesOf: (NSString *)superClass
{
  NSMutableArray *array = [NSMutableArray array];
  [self allSubclassesOf: superClass
	referenceClassList: customClasses
	intoArray: array];

  // add known allowable subclasses to the list.
  if([superClass isEqualToString: @"NSWindow"])
    {
      [array addObject: @"NSPanel"];
    }
  else if([superClass isEqualToString: @"NSTextField"])
    {
      [array addObject: @"NSSecureTextField"];
    }

  return array;
}

- (NSArray *) customSubClassesOf: (NSString *)superclass
{
  NSEnumerator *cen   = [customClasses objectEnumerator];
  id object = nil;
  NSMutableArray *subclasses = [NSMutableArray array];

  while((object = [cen nextObject]))
    {
      NSDictionary *dictForClass = [classInformation objectForKey: object];
      if([[dictForClass objectForKey: @"Super"] isEqual: superclass])
	{
	  [subclasses addObject: object];
	}
    }
      
  return subclasses;
}

- (NSArray *) subClassesOf: (NSString *)superclass
{
  NSArray *allClasses = [classInformation allKeys];
  NSEnumerator *cen   = [allClasses objectEnumerator];
  id object = nil;
  NSMutableArray *subclasses = [NSMutableArray array];

  while((object = [cen nextObject]))
    {
      NSDictionary *dictForClass = [classInformation objectForKey: object];
      if([[dictForClass objectForKey: @"Super"] isEqual: superclass])
	{
	  [subclasses addObject: object];
	}
    }
      
  return subclasses;
}

- (void) removeAction: (NSString*)anAction forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraActions = [info objectForKey: @"ExtraActions"];

  if ([extraActions containsObject: anAction] == YES)
    {
      NSString	*superName = [info objectForKey: @"Super"];

      if (superName != nil)
	{
	  NSArray	*superActions;

	  /*
	   * If this action is new in this class (ie not overriding an
	   * action in a parent) then we remove it from the list of all
	   * actions that the object responds to.
	   */
	  superActions = [self allActionsForClassNamed: superName];
	  if ([superActions containsObject: anAction] == NO)
	    {
	      NSMutableArray	*array = [info objectForKey: @"AllActions"];

	      [array removeObject: anAction];
	    }
	}
      [extraActions removeObject: anAction];
    }
}

- (void) removeAction: (NSString*)anAction fromClassNamed: (NSString *)className
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];
  NSMutableArray	*extraActions = [info objectForKey: @"ExtraActions"];

  if ([extraActions containsObject: anAction] == YES)
    {
      NSString	*superName = [info objectForKey: @"Super"];

      if (superName != nil)
	{
	  NSArray	*superActions;

	  /*
	   * If this action is new in this class (ie not overriding an
	   * action in a parent) then we remove it from the list of all
	   * actions that the object responds to.
	   */
	  superActions = [self allActionsForClassNamed: superName];
	  if ([superActions containsObject: anAction] == NO)
	    {
	      NSMutableArray	*array = [info objectForKey: @"AllActions"];

	      [array removeObject: anAction];
	    }
	}
      [extraActions removeObject: anAction];
    }
}

- (void) removeOutlet: (NSString*)anOutlet forObject: (id)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];
  NSMutableArray	*extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSMutableArray	*allOutlets = [info objectForKey: @"AllOutlets"];

  if ([extraOutlets containsObject: anOutlet] == YES)
    {
      [extraOutlets removeObject: anOutlet];
    }
  if ([allOutlets containsObject: anOutlet] == YES)
    {
      [allOutlets removeObject: anOutlet];
    }
}

- (void) removeOutlet: (NSString*)anOutlet fromClassNamed: (NSString *)className
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];
  NSMutableArray	*extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSMutableArray	*allOutlets = [info objectForKey: @"AllOutlets"];

  if ([extraOutlets containsObject: anOutlet] == YES)
    {
      [extraOutlets removeObject: anOutlet];
    }
  if ([allOutlets containsObject: anOutlet] == YES)
    {
      [allOutlets removeObject: anOutlet];
    }
}

- (void) removeClassNamed: (NSString *)className
{
  if([customClasses containsObject: className])
    {
      [customClasses removeObject: className];
    }

  [classInformation removeObjectForKey: className];
}

- (BOOL) renameClassNamed: (NSString*)oldName newName: (NSString*)name
{
  id classInfo = [classInformation objectForKey: oldName];

  if (classInfo != nil && [classInformation objectForKey: name] == nil)
    {
      int index = 0;

      RETAIN(classInfo);

      [classInformation removeObjectForKey: oldName];
      [classInformation setObject: classInfo forKey: name];

      RELEASE(classInfo);

      if((index = [customClasses indexOfObject: oldName]) != NSNotFound)
	{
	  [customClasses replaceObjectAtIndex: index withObject: name];
	}

      [[NSNotificationCenter defaultCenter]
	postNotificationName: IBClassNameChangedNotification object: self];
      return YES;
    }
  else return NO;

}
- (BOOL) saveToFile: (NSString*)path
{
  NSMutableDictionary	*ci;
  NSEnumerator		*enumerator;
  id			key;

  ci = AUTORELEASE([[NSMutableDictionary alloc] initWithCapacity: 0]);
  enumerator = [customClasses objectEnumerator];
  while ((key = [enumerator nextObject]) != nil)
    {
      NSDictionary		*classInfo;
      NSMutableDictionary	*newInfo;
      id			obj;
      id                        extraObj;

      classInfo = [classInformation objectForKey: key];
      newInfo = [NSMutableDictionary new];
      [ci setObject: newInfo forKey: key];
      RELEASE(newInfo);

      obj = [classInfo objectForKey: @"Super"];
      if (obj != nil)
	{
	  [newInfo setObject: obj forKey: @"Super"];
	}
      obj = [classInfo objectForKey: @"Outlets"];
      extraObj = [classInfo objectForKey: @"ExtraOutlets"];
      if (obj && extraObj)
	{
	  obj = [obj arrayByAddingObjectsFromArray: extraObj];
	}
      else if (extraObj)
	{
	  obj = extraObj;
	}
      if (obj != nil)
	{
	  [newInfo setObject: obj forKey: @"Outlets"];
	}
      obj = [classInfo objectForKey: @"Actions"];
      extraObj = [classInfo objectForKey: @"ExtraActions"];
      if (obj && extraObj)
	{
	  obj = [obj arrayByAddingObjectsFromArray: extraObj];
	}
      else if (extraObj)
	{
	  obj = extraObj;
	}
      if (obj != nil)
	{
	  [newInfo setObject: obj forKey: @"Actions"];
	}
    }

  return [ci writeToFile: path atomically: YES];
}

- (BOOL) loadFromFile: (NSString*)path
{
  NSDictionary		*dict;
  NSEnumerator		*enumerator;
  NSString		*key;

  NSLog(@"Load from file %@",path);

  dict = [NSDictionary dictionaryWithContentsOfFile: path];
  // customClasses = [NSMutableArray arrayWithCapacity: 1];
  if (dict == nil)
    {
      NSLog(@"Could not load classes dictionary");
      return NO;
    }
  /*
   * Convert property-list data into a mutable structure.
   */
  RELEASE(classInformation);
  classInformation = [NSMutableDictionary new];
  enumerator = [dict keyEnumerator];
  while ((key = [enumerator nextObject]) != nil)
    {
      NSDictionary		*classInfo = [dict objectForKey: key];
      NSMutableDictionary	*newInfo;
      NSMutableDictionary       *oldInfo;
      id			obj;

      newInfo = [NSMutableDictionary new];
      oldInfo = [classInformation objectForKey: key];
    
      [classInformation setObject: newInfo forKey: key];
      RELEASE(newInfo);
      
      obj = [classInfo objectForKey: @"Super"];
      if (obj != nil)
	{
	  [newInfo setObject: obj forKey: @"Super"];
	}
      
      // outlets
      obj = [classInfo objectForKey: @"Outlets"];
      if (obj != nil)
	{
	  obj = [obj mutableCopy];
	  [obj sortUsingSelector: @selector(compare:)];
	  [newInfo setObject: obj forKey: @"Outlets"];
	  RELEASE(obj);
	}

      // actions
      obj = [classInfo objectForKey: @"Actions"];
      if (obj != nil)
	{
	  obj = [obj mutableCopy];
	  [obj sortUsingSelector: @selector(compare:)];
	  [newInfo setObject: obj forKey: @"Actions"];
	  RELEASE(obj);
	}
    }
  return YES;
}

- (void) _convertDictionary: (NSMutableDictionary *)dict
{
  NSMutableArray *array = [classInformation allKeys];
  [dict removeObjectsForKeys: array];
}

// this method will load the custom classes and merge them with the
// Class information loaded at initialization time.
- (BOOL)loadCustomClasses: (NSString *)path
{
  NSMutableDictionary		*dict;

  NSLog(@"Load custom classes from file %@",path);

  dict = [NSMutableDictionary dictionaryWithContentsOfFile: path];
  if (dict == nil)
    {
      NSLog(@"Could not load custom classes dictionary");
      return NO;
    }
  
  if(classInformation == nil)
    {
      NSLog(@"Default classes file not loaded");
      return NO;
    }

  if([[dict allKeys] containsObject: @"NSObject"])
    {
      NSLog(@"The file being loaded is in the old .classes format.  Updating..");
      [self _convertDictionary: dict];
    }

  [customClasses addObjectsFromArray: [dict allKeys]];
  [classInformation addEntriesFromDictionary: dict];

  return YES;
}

- (BOOL) isCustomClass: (NSString *)className
{
  return ([customClasses indexOfObject: className] != NSNotFound);
}

- (BOOL) setSuperClassNamed: (NSString*)superclass
	      forClassNamed: (NSString*)subclass
{
  NSArray *cn = [self allClassNames];

  if (superclass != nil && subclass != nil && [cn containsObject: subclass]
    && ([cn containsObject: superclass]
    || [superclass isEqualToString: @"NSObject"])
    && [self isSuperclass: subclass linkedToClass: superclass] == NO)
    {
      NSMutableDictionary	*info;

      info = [classInformation objectForKey: subclass];
      if (info != nil)
	{
	  [info setObject: superclass forKey: @"Super"];
	  return YES;
	}
      else
	{
	  return NO;
	}
    }
  else
    {
      return NO;
    }
}

- (NSString*) superClassNameForClassNamed: (NSString*)className
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];
  NSString		*superName = nil;

  if (info != nil)
    {
      superName = [info objectForKey: @"Super"];
    }
  if (superName == nil)
    {
      superName = @"NSObject";
    }
  return superName;

}

- (BOOL) isSuperclass: (NSString*)superclass linkedToClass: (NSString*)subclass
{
  NSString *ssclass;

  //NSLog(@"isSuperClass : %@, %@", superclass, subclass);

  if (superclass == nil || subclass == nil)
    {
      return NO;
    }
  if ([superclass isEqualToString: @"NSObject"])
    {
      return YES;
    }
  if ([subclass isEqualToString: @"NSObject"])
    {
      return NO;
    }
  ssclass = [self superClassNameForClassNamed: subclass];
  if ([superclass isEqualToString: ssclass])
    {
      return YES;
    }
  else
    {
      return [self isSuperclass: superclass linkedToClass: ssclass];
    }
}


/*
 *  create .m & .h files for a class
 */
- (BOOL) makeSourceAndHeaderFilesForClass: (NSString*)className 
				 withName: (NSString*)sourcePath
				      and: (NSString*)headerPath
{
  NSMutableString	*headerFile;
  NSMutableString	*sourceFile;
  NSData		*headerData;
  NSData		*sourceData;
  NSArray		*outlets;
  NSArray		*actions;
  NSString		*actionName;
  int			i;
  int			n;

  headerFile = [NSMutableString stringWithCapacity: 200];
  sourceFile = [NSMutableString stringWithCapacity: 200];
  outlets = [self allOutletsForClassNamed: className];
  actions = [self allActionsForClassNamed: className];
  
  [headerFile appendString: @"/* All Rights reserved */\n\n"];
  [sourceFile appendString: @"/* All Rights reserved */\n\n"];
  [headerFile appendString: @"#import <AppKit/AppKit.h>\n\n"];
  [sourceFile appendString: @"#import <AppKit/AppKit.h>\n"];
  if ([[headerPath stringByDeletingLastPathComponent]
    isEqualToString: [sourcePath stringByDeletingLastPathComponent]])
    {
      [sourceFile appendFormat: @"#import \"%@\"\n\n", 
	[headerPath lastPathComponent]];
    }
  else
    {
      [sourceFile appendFormat: @"#import \"%@\"\n\n", 
	headerPath];      
    }
  [headerFile appendFormat: @"@interface %@ : %@\n{\n", className,
    [self superClassNameForClassNamed: className]];
  [sourceFile appendFormat: @"@implementation %@\n\n", className];
  
  n = [outlets count]; 
  for (i = 0; i < n; i++)
    {
      [headerFile appendFormat: @"  id %@;\n", [outlets objectAtIndex: i]];
    }
  [headerFile appendFormat: @"}\n"];

  n = [actions count]; 
  for (i = 0; i < n; i++)
    {
      actionName = [actions objectAtIndex: i];
      [headerFile appendFormat: @"- (void) %@ (id)sender;\n", actionName];
      [sourceFile appendFormat:
	@"\n"
	@"- (void) %@ (id)sender\n"
	@"{\n"
	@"  /* insert your code here */\n"
	@"}\n"
	@"\n"
	, [actions objectAtIndex: i]];
    }
  [headerFile appendFormat: @"@end\n"];
  [sourceFile appendFormat: @"@end\n"];

  headerData = [headerFile dataUsingEncoding:
    [NSString defaultCStringEncoding]];
  sourceData = [sourceFile dataUsingEncoding:
    [NSString defaultCStringEncoding]];

  [headerData writeToFile: headerPath atomically: NO];
  [sourceData writeToFile: sourcePath atomically: NO];

  return YES;
}

- (BOOL) isAction: (NSString *)name ofClass: (NSString *)className
{
  BOOL result = NO;
  NSDictionary *classInfo = [classInformation objectForKey: className];
  
  if(classInfo != nil)
    {
      NSArray *array = [classInfo objectForKey: @"Actions"];
      NSArray *extra_array = [classInfo objectForKey: @"ExtraActions"];
      NSMutableArray *combined = [NSMutableArray array];

      [combined addObjectsFromArray: array];
      [combined addObjectsFromArray: extra_array];
      result = ([combined indexOfObject: name] != NSNotFound);
    }

  return result;
}

- (BOOL) isOutlet: (NSString *)name ofClass: (NSString *)className
{
  BOOL result = NO;
  NSDictionary *classInfo = [classInformation objectForKey: className];
  
  if(classInfo != nil)
    {
      NSArray *array = [classInfo objectForKey: @"Outlets"];
      NSArray *extra_array = [classInfo objectForKey: @"ExtraOutlets"];
      NSMutableArray *combined = [NSMutableArray array];

      [combined addObjectsFromArray: array];
      [combined addObjectsFromArray: extra_array];
      result = ([combined indexOfObject: name] != NSNotFound);
    }

  return result;
}

// custom class support...
- (NSString *) customClassForObject: (id)object
{
  return [customClassMap objectForKey: object];
}

- (void) setCustomClass: (NSString *)className
              forObject: (id)object
{
  // NSString *name = [NSString stringWithString: className];
  [customClassMap setObject: className forKey: object];
}

- (void) removeCustomClassForObject: (id) object
{
  [customClassMap removeObjectForKey: object];
}

- (NSMutableDictionary *)customClassMap
{
  return customClassMap;
}

- (void)setCustomClassMap: (NSMutableDictionary *)dict
{
  // copy the dictionary..
  NSLog(@"dictionary = %@",dict);
  ASSIGN(customClassMap, dict);
  RETAIN(customClassMap);
}

- (BOOL)isCustomClassMapEmpty
{
  return ([customClassMap count] == 0);
}

- (NSString *)nonCustomSuperClassOf: (NSString *)className
{
  NSString *result = className;

  // iterate up the chain until a non-custom superclass is found...
  while([self isCustomClass: result])
    {
      NSLog(@"result = %@",result);
      result = [self superClassNameForClassNamed: result];
    }

  return result;
}

@end
