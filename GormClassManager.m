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
#include "GormDocument.h"
#include "GormFilesOwner.h"
#include "GormPalettesManager.h"
#include <InterfaceBuilder/IBEditors.h>
#include <InterfaceBuilder/IBPalette.h>

/** Private methods not accesible from outside */
@interface GormClassManager (Private)
- (NSMutableDictionary*) classInfoForClassName: (NSString*)className;
- (NSMutableDictionary*) classInfoForObject: (id)anObject;
- (void) touch;
- (void) convertDictionary: (NSMutableDictionary *)dict;
@end

@implementation GormClassManager

- (id) initWithDocument: (id)aDocument
{
  self = [super init];
  if (self != nil)
    {
      NSBundle			*bundle = [NSBundle mainBundle];
      NSString			*path;

      document = aDocument;  // the document retains us, this is for convenience

      path = [bundle pathForResource: @"ClassInformation" ofType: @"plist"];
      if (path == nil)
	{
	  NSLog(@"ClassInformation.plist missing from resources");
	}
      else
	{
	  GormPalettesManager *palettesManager = [(Gorm *)NSApp palettesManager];

	  // load the classes, initialize the custom class array and map..
	  [self loadFromFile: path];
	  customClasses = [[NSMutableArray alloc] initWithCapacity: 1];
	  customClassMap = [[NSMutableDictionary alloc] initWithCapacity: 10]; 
	  categoryClasses = [[NSMutableArray alloc] initWithCapacity: 1];

	  // add first responder so that it may be edited.
	  [customClasses addObject: @"FirstResponder"];
	  
	  // add the imported classes to the class information list...
	  [classInformation addEntriesFromDictionary: [palettesManager importedClasses]];
	}
    }
  
  return self;
}

- (void) touch
{
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: GormDidModifyClassNotification
    object: self];
  [document touch];
}

- (void) convertDictionary: (NSMutableDictionary *)dict
{
  NSMutableArray *array = [classInformation allKeys];
  [dict removeObjectsForKeys: array];
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
      [classInfo setObject: actions forKey: @"Actions"];
      [classInfo setObject: name forKey: @"Super"];

      while ([classInformation objectForKey: newClassName] != nil)
	{
	  newClassName = [newClassName stringByAppendingString:
	    [NSString stringWithFormat: @"%d", i++]];

	}
      [classInformation setObject: classInfo forKey: newClassName];
      [customClasses addObject: newClassName];

      [self touch];

      [[NSNotificationCenter defaultCenter] 
	postNotificationName: GormDidAddClassNotification
	object: self];

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
  NSString *newAction = @"newAction";
  NSString *search = [newAction stringByAppendingString: @":"];
  NSString *new = nil; 
  int i = 1;

  [combined addObjectsFromArray: extra];
  while ([combined containsObject: search])
    {
      new = [newAction stringByAppendingFormat: @"%d", i++];
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
  NSString *newOutlet = @"newOutlet";
  NSString *new = newOutlet;
  int i = 1;

  [combined addObjectsFromArray: extra];
  while ([combined containsObject: new])
    {
      new = [newOutlet stringByAppendingFormat: @"%d", i++];
    }

  [self addOutlet: new forClassNamed: name];
  return new;
}

- (BOOL) addClassNamed: (NSString*)class_name
   withSuperClassNamed: (NSString*)super_class_name
	   withActions: (NSArray*)_actions
	   withOutlets: (NSArray*)_outlets
{
  return [self addClassNamed: class_name
	       withSuperClassNamed: super_class_name
	       withActions: _actions
	       withOutlets: _outlets
	       isCustom: YES];
}

- (BOOL) addClassNamed: (NSString*)class_name
   withSuperClassNamed: (NSString*)super_class_name
	   withActions: (NSArray*)_actions
	   withOutlets: (NSArray*)_outlets
	      isCustom: (BOOL) isCustom
{
  BOOL result = NO;
  NSString *className = [class_name copy];
  NSString *superClassName = [super_class_name copy];
  NSArray  *actions = [_actions copy];
  NSArray  *outlets = [_outlets copy];

  if ([superClassName isEqualToString: @"NSObject"]
    || [classInformation objectForKey: superClassName] != nil)
    {
      NSMutableDictionary	*classInfo;

      if (![classInformation objectForKey: className])
	{
	  NSEnumerator *e = [actions objectEnumerator];
	  id action = nil;

	  [self touch];
	  classInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
	  
	  [classInfo setObject: outlets forKey: @"Outlets"];
	  [classInfo setObject: actions forKey: @"Actions"];
	  [classInfo setObject: superClassName forKey: @"Super"];
	  [classInformation setObject: classInfo forKey: className];
	  
	  // if it's a custom class add it to the list.
	  if(isCustom)
	    {
	      [customClasses addObject: className];
	    }

	  // copy all actions from the class imported to the first responder
	  while((action = [e nextObject]))
	    {
	      // if([self isSuperclass: @"NSResponder" linkedToClass: className])
		{
		  [self addAction: action forClassNamed: @"FirstResponder"];
		}
	    }

	  result = YES;

	  // post the notification
	  [[NSNotificationCenter defaultCenter] 
	    postNotificationName: GormDidAddClassNotification
	    object: self];
	}
      else
	{
	  NSDebugLog(@"Class already exists");
	  result = NO;
	}
    }

  return result;
}

- (void) addAction: (NSString*)anAction forObject: (id)anObject
{
  [self addAction: anAction forClassNamed: [anObject className]];
}

- (void) addAction: (NSString *)action forClassNamed: (NSString *)className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraActions = [info objectForKey: @"ExtraActions"];
  NSArray *allActions = [self allActionsForClassNamed: className];
  NSString *anAction = [action copy];
  NSEnumerator *en = [[self subClassesOf: className] objectEnumerator];
  NSString *subclassName = nil;

  if ([allActions containsObject: anAction])
    {
      return;
    }

  if (extraActions == nil)
    {
      extraActions = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraActions forKey: @"ExtraActions"];
    }

  [extraActions addObject: anAction];
  [[info objectForKey: @"AllActions"] insertObject: anAction atIndex: 0];
  if(![className isEqualToString: @"FirstResponder"]) 
    {
      [self addAction: anAction forClassNamed: @"FirstResponder"];
    }

  while((subclassName = [en nextObject]) != nil)
    {
      [self addAction: anAction forClassNamed: subclassName];
    }

  [self touch];
}

- (void) addOutlet: (NSString*)outlet forObject: (id)anObject
{
  [self addOutlet: outlet forClassNamed: [anObject className]];
}

- (void) addOutlet: (NSString *)outlet forClassNamed: (NSString *)className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSArray *allOutlets = [self allOutletsForClassNamed: className];
  NSString *anOutlet = [outlet copy];
  NSEnumerator *en = [[self subClassesOf: className] objectEnumerator];
  NSString *subclassName = nil;

  if ([allOutlets containsObject: anOutlet])
    {
      return;
    }

  if (extraOutlets == nil)
    {
      extraOutlets = [[NSMutableArray alloc] initWithCapacity: 1];
      [info setObject: extraOutlets forKey: @"ExtraOutlets"];
    }

  [extraOutlets addObject: anOutlet];
  [[info objectForKey: @"AllOutlets"] insertObject: anOutlet atIndex: 0];

  while((subclassName = [en nextObject]) != nil)
    {
      [self addOutlet: outlet forClassNamed: subclassName];
    }

  [self touch];
}

- (void) replaceAction: (NSString *)oldAction
	    withAction: (NSString *)new_action
	 forClassNamed: className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraActions = [info objectForKey: @"ExtraActions"];
  NSMutableArray *actions = [info objectForKey: @"Actions"];
  NSMutableArray *allActions = [info objectForKey: @"AllActions"];
  NSString *newAction = [new_action copy];
  NSEnumerator *en = [[self subClassesOf: className] objectEnumerator];
  NSString *subclassName = nil;

  if ([allActions containsObject: newAction]
    || [extraActions containsObject: newAction])
    {
      return;
    }

  if ([extraActions containsObject: oldAction])
    {
      int all_index = [allActions indexOfObject: oldAction];
      int extra_index = [extraActions indexOfObject: oldAction];

      [extraActions replaceObjectAtIndex: extra_index withObject: newAction];
      [allActions replaceObjectAtIndex: all_index withObject: newAction];
    }
  else if ([actions containsObject: oldAction])
    {
      int all_index = [allActions indexOfObject: oldAction];
      int actions_index = [actions indexOfObject: oldAction];

      [actions replaceObjectAtIndex: actions_index withObject: newAction];
      [allActions replaceObjectAtIndex: all_index withObject: newAction];
    }

  [self touch];

  // add the action to all of the subclasses, in the "AllActions" section...
  while((subclassName = [en nextObject]) != nil)
    {
      [self replaceOutlet: oldAction withOutlet: new_action forClassNamed: subclassName];
    }

  if(![className isEqualToString: @"FirstResponder"]) 
    {
      [self replaceAction: oldAction withAction: newAction forClassNamed: @"FirstResponder"];
    }
}

- (void) replaceOutlet: (NSString *)oldOutlet
	    withOutlet: (NSString *)new_outlet
	 forClassNamed: className
{
  NSMutableDictionary *info = [classInformation objectForKey: className]; 
  NSMutableArray *extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSMutableArray *outlets = [info objectForKey: @"Outlets"];
  NSMutableArray *allOutlets = [info objectForKey: @"AllOutlets"];
  NSString *newOutlet = [new_outlet copy];
  NSEnumerator *en = [[self subClassesOf: className] objectEnumerator];
  NSString *subclassName = nil;

  if ([allOutlets containsObject: newOutlet]
    || [extraOutlets containsObject: newOutlet])
    {
      return;
    }

  if ([extraOutlets containsObject: oldOutlet])
    {
      int all_index = [allOutlets indexOfObject: oldOutlet];
      int extra_index = [extraOutlets indexOfObject: oldOutlet];

      [extraOutlets replaceObjectAtIndex: extra_index withObject: newOutlet];
      [allOutlets replaceObjectAtIndex: all_index withObject: newOutlet];
    }
  else if ([outlets containsObject: oldOutlet])
    {
      int all_index = [allOutlets indexOfObject: oldOutlet];
      int outlets_index = [outlets indexOfObject: oldOutlet];

      [outlets replaceObjectAtIndex: outlets_index withObject: newOutlet];
      [allOutlets replaceObjectAtIndex: all_index withObject: newOutlet];
    }

  [self touch];

  // add the action to all of the subclasses, in the "AllActions" section...
  while((subclassName = [en nextObject]) != nil)
    {
      [self replaceOutlet: oldOutlet withOutlet: new_outlet forClassNamed: subclassName];
    }
}

- (void) removeAction: (NSString*)anAction forObject: (id)anObject
{
  [self removeAction: anAction fromClassNamed: [anObject className]];
}

- (void) removeAction: (NSString*)anAction
       fromClassNamed: (NSString *)className
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];
  NSMutableArray	*extraActions = [info objectForKey: @"ExtraActions"];
  NSMutableArray        *allActions = [info objectForKey: @"AllActions"];
  NSEnumerator *en = [[self subClassesOf: className] objectEnumerator];
  NSString *subclassName = nil;

  if ([extraActions containsObject: anAction] == YES
    || [allActions containsObject: anAction] == YES)
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
	      NSMutableArray    *actions = [info objectForKey: @"Actions"];
	      [array removeObject: anAction];
	      [actions removeObject: anAction];
	    }
	}
      [extraActions removeObject: anAction];
      [self touch];
    }

  if(![className isEqualToString: @"FirstResponder"]) 
    {
      [self removeAction: anAction fromClassNamed: @"FirstResponder"];
    }

  while((subclassName = [en nextObject]) != nil)
    {
      [self removeAction: anAction fromClassNamed: subclassName];
    }
}

- (void) removeOutlet: (NSString*)anOutlet forObject: (id)anObject
{
  [self removeOutlet: anOutlet fromClassNamed: [anObject className]];
}

- (void) removeOutlet: (NSString*)anOutlet fromClassNamed: (NSString *)className
{
  NSMutableDictionary	*info = [classInformation objectForKey: className];
  NSMutableArray	*extraOutlets = [info objectForKey: @"ExtraOutlets"];
  NSMutableArray	*allOutlets = [info objectForKey: @"AllOutlets"];
  NSEnumerator *en = [[self subClassesOf: className] objectEnumerator];
  NSString *subclassName = nil;

  if ([extraOutlets containsObject: anOutlet] == YES
    || [allOutlets containsObject: anOutlet] == YES)
    {
      NSString	*superName = [info objectForKey: @"Super"];

      if (superName != nil)
	{
	  NSArray	*superOutlets;

	  // remove the outlet from the other arrays...
	  superOutlets = [self allOutletsForClassNamed: superName];
	  if ([superOutlets containsObject: anOutlet] == NO)
	    {
	      NSMutableArray	*array = [info objectForKey: @"AllOutlets"];
	      NSMutableArray    *actions = [info objectForKey: @"Outlets"];
	      [array removeObject: anOutlet];
	      [actions removeObject: anOutlet];
	    }
	}
      [extraOutlets removeObject: anOutlet];
      [self touch];
    }

  while((subclassName = [en nextObject]) != nil)
    {
      [self removeOutlet: anOutlet fromClassNamed: subclassName];
    }
}


- (NSArray*) allActionsForObject: (id)obj
{
  NSString	*className;
  NSArray	*actions;
  Class		 theClass = [obj class];
  NSString      *customClassName = [self customClassForObject: obj];
  
  NSDebugLog(@"** ACTIONS");
  NSDebugLog(@"Object: %@",obj);
  NSDebugLog(@"Custom class: %@",customClassName);
  if (customClassName != nil)
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
      // NSLog(@"attempt to get actions for non-existent class (%@)",	
      //	[obj class]);
      return nil;
    }

  actions = [self allActionsForClassNamed: className];
  while (actions == nil && (theClass = class_get_super_class(theClass)) != nil
    && theClass != [NSObject class])
    {
      className = NSStringFromClass(theClass);
      actions = [self allActionsForClassNamed: className];
    }

  NSDebugLog(@"class=%@ actions=%@",className,actions);
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
	}
      return AUTORELEASE([allActions copy]);
    }
  return nil;
}

- (NSArray*) allCustomClassNames
{
  return [customClassMap allKeys];
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

  NSDebugLog(@"** OUTLETS");
  NSDebugLog(@"Object: %@",obj);
  NSDebugLog(@"Custom class: %@",customClassName);
  if (customClassName != nil)
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
  RELEASE(customClassMap);
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

- (void) allSubclassesOf: (NSString *)superclass
      referenceClassList: (NSArray *)classList
	       intoArray: (NSMutableArray *)array
{
  NSEnumerator *cen   = [classList objectEnumerator];
  id object = nil;

  while ((object = [cen nextObject]))
    {
      NSDictionary *dictForClass = [classInformation objectForKey: object];
      if ([[dictForClass objectForKey: @"Super"] isEqual: superclass])
	{
	  [array addObject: object];
	  [self allSubclassesOf: object
	     referenceClassList: classList
		      intoArray: array];
	}
    }
}

- (NSArray *) allSubclassesOf: (NSString *)superClass
{
  NSMutableArray *array = [NSMutableArray array];
  
  if(superClass != nil)
    {
      [self allSubclassesOf: superClass
	    referenceClassList: [classInformation allKeys]
	    intoArray: array];
    }

  return array;
}

- (NSArray *) allCustomSubclassesOf: (NSString *)superClass
{
  NSMutableArray *array = [NSMutableArray array];

  [self allSubclassesOf: superClass
     referenceClassList: customClasses
	      intoArray: array];

  // add known allowable subclasses to the list.
  if ([superClass isEqualToString: @"NSTextField"])
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

  while ((object = [cen nextObject]))
    {
      NSDictionary *dictForClass = [classInformation objectForKey: object];

      if ([[dictForClass objectForKey: @"Super"] isEqual: superclass])
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

  while ((object = [cen nextObject]))
    {
      NSDictionary *dictForClass = [classInformation objectForKey: object];

      if ([[dictForClass objectForKey: @"Super"] isEqual: superclass])
	{  
	  [subclasses addObject: object];
	}
    }
      
  return subclasses;
}

- (void) removeClassNamed: (NSString *)className
{
  if ([customClasses containsObject: className])
    {
      NSEnumerator *en = [customClassMap keyEnumerator];
      id object = nil;
      id owner = nil;

      [customClasses removeObject: className];
      
      while((object = [en nextObject]) != nil)
	{
	  id customClassName = [customClassMap objectForKey: object];
	  if(customClassName != nil)
	    {
	      if([className isEqualToString: customClassName])
		{
		  NSDebugLog(@"Deleting object -> customClass association %@ -> %@",object,customClassName);
		  [customClassMap removeObjectForKey: object];
		}
	    }
	}

      // get the owner and reset the class name to NSApplication.
      owner = [document objectForName: @"NSOwner"];
      if([className isEqual: [owner className]])
	{
	  [owner setClassName: @"NSApplication"];
	}
    }

  [classInformation removeObjectForKey: className];
  [self touch];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName: GormDidDeleteClassNotification
    object: self];
}

- (BOOL) renameClassNamed: (NSString*)oldName newName: (NSString*)newName
{
  id classInfo = [classInformation objectForKey: oldName];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  NSString *name = [newName copy];

  NSDebugLog(@"Old name %@, new name %@",oldName,name);

  if (classInfo != nil && [classInformation objectForKey: name] == nil)
    {
      int index = 0;
      NSArray *subclasses = [self subClassesOf: oldName];

      RETAIN(classInfo); // prevent loss of the information...
      [classInformation removeObjectForKey: oldName];
      [classInformation setObject: classInfo forKey: name];
      RELEASE(classInfo); // release our hold on it.

      if ((index = [customClasses indexOfObject: oldName]) != NSNotFound)
	{
	  NSEnumerator *en = [customClassMap keyEnumerator];
	  NSEnumerator *cen = [subclasses objectEnumerator];
	  id sc = nil;
	  id object = nil;

	  NSDebugLog(@"replacing object with %@, %@",name, customClasses);
	  [customClasses replaceObjectAtIndex: index withObject: name];
	  NSDebugLog(@"replaced object with %@, %@",name, customClasses);

	  // show the class map before...
	  NSDebugLog(@"customClassMap = %@",customClassMap);
	  while((object = [en nextObject]) != nil)
	    {
	      id customClassName = [customClassMap objectForKey: object];
	      if(customClassName != nil)
		{
		  if([oldName isEqualToString: customClassName])
		    {
		      NSDebugLog(@"Replacing object -> customClass association %@ -> %@",object,customClassName);
		      [customClassMap setObject: name forKey: object];
		    }
		}
	    }
	  NSDebugLog(@"New customClassMap = %@",customClassMap); // and after

	  // Iterate over the list of subclasses and replace their referece with the new
	  // name.
	  while((sc = [cen nextObject]) != nil)
	    {
	      [self setSuperClassNamed: name
		    forClassNamed: sc];
	    }

	  [self touch];
	}
      else
	NSLog(@"customClass not found %@",oldName);

      [nc postNotificationName: IBClassNameChangedNotification object: self];
      return YES;
    }
  else return NO;
}

- (NSString *)parentOfClass: (NSString *)aClass
{
  NSDictionary *dictForClass = [classInformation objectForKey: aClass];
  return [dictForClass objectForKey: @"Super"];
}

- (BOOL) saveToFile: (NSString*)path
{
  NSMutableDictionary	*ci;
  NSEnumerator		*enumerator;
  id			 key;
  NSMutableArray        *classesToSave;
  
  classesToSave = [customClasses arrayByAddingObjectsFromArray: categoryClasses];
  ci = AUTORELEASE([[NSMutableDictionary alloc] initWithCapacity: 0]);
  enumerator = [customClasses objectEnumerator];
  while ((key = [enumerator nextObject]) != nil)
    {
      NSDictionary		*classInfo;
      NSMutableDictionary	*newInfo;
      id			obj;
      id                        extraObj;

      // superclass...
      classInfo = [classInformation objectForKey: key];
      newInfo = [NSMutableDictionary new];
      [ci setObject: newInfo forKey: key];

      obj = [classInfo objectForKey: @"Super"];
      if (obj != nil)
	{
	  [newInfo setObject: obj forKey: @"Super"];
	}

      // outlets...
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

      // actions...
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

  NSDebugLog(@"Load from file %@",path);

  dict = [NSDictionary dictionaryWithContentsOfFile: path];
  if (dict == nil)
    {
      NSLog(@"Could not load classes dictionary");
      return NO;
    }

  /*
   * Convert property-list data into a mutable structure.
   */
  RELEASE(classInformation);
  classInformation = [[NSMutableDictionary alloc] init];
  enumerator = [dict keyEnumerator];
  while ((key = [enumerator nextObject]) != nil)
    {
      NSDictionary	    *classInfo = [dict objectForKey: key];
      NSMutableDictionary   *newInfo;
      NSMutableDictionary   *oldInfo;
      id		    obj;
      
      newInfo = [NSMutableDictionary new];
      oldInfo = [classInformation objectForKey: key];
      
      [classInformation setObject: newInfo forKey: key];
      
      // superclass
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

// this method will load the custom classes and merge them with the
// Class information loaded at initialization time.
- (BOOL) loadCustomClasses: (NSString *)path
{
  NSMutableDictionary		*dict;
  NSEnumerator                  *en;
  id                            obj;

  NSDebugLog(@"Load custom classes from file %@",path);

  dict = [NSMutableDictionary dictionaryWithContentsOfFile: path];
  if (dict == nil)
    {
      NSLog(@"Could not load custom classes dictionary");
      return NO;
    }
  
  if (classInformation == nil)
    {
      NSLog(@"Default classes file not loaded");
      return NO;
    }

  if ([[dict allKeys] containsObject: @"NSObject"])
    {
      NSLog(@"The file being loaded is in the old .classes format.  Updating..");
      [self convertDictionary: dict];
    }

  [customClasses addObjectsFromArray: [dict allKeys]];
  [classInformation addEntriesFromDictionary: dict];

  return YES;
}

- (BOOL) isCustomClass: (NSString *)className
{
  return ([customClasses indexOfObject: className] != NSNotFound); 
}

- (BOOL) isNonCustomClass: (NSString *)className
{
  return !([self isCustomClass: className]); 
}

- (BOOL) isCategoryForClass: (NSString *)className
{
  return ([categoryClasses indexOfObject: className] != NSNotFound); 
}

- (BOOL) isKnownClass: (NSString *)className
{
  return ([classInformation objectForKey: className] != nil);
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
  NSMutableArray	*outlets;
  NSMutableArray	*actions;
  NSString		*actionName;
  int			i;
  int			n;
  NSDictionary          *classInfo = [classInformation objectForKey: className];

  headerFile = [NSMutableString stringWithCapacity: 200];
  sourceFile = [NSMutableString stringWithCapacity: 200];

  // add all outlets and actions for the current class to the list...
  outlets = [[classInfo objectForKey: @"Outlets"] mutableCopy];
  [outlets addObjectsFromArray: [classInfo objectForKey: @"ExtraOutlets"]]; 
  actions = [[classInfo objectForKey: @"Actions"] mutableCopy]; 
  [actions addObjectsFromArray: [classInfo objectForKey: @"ExtraActions"]]; 
  
  // header file comments...
  [headerFile appendString: @"/* All Rights reserved */\n\n"];
  [sourceFile appendString: @"/* All Rights reserved */\n\n"];
  [headerFile appendString: @"#include <AppKit/AppKit.h>\n\n"];
  [sourceFile appendString: @"#include <AppKit/AppKit.h>\n"];
  if ([[headerPath stringByDeletingLastPathComponent]
    isEqualToString: [sourcePath stringByDeletingLastPathComponent]])
    {
      [sourceFile appendFormat: @"#include \"%@\"\n\n", 
	[headerPath lastPathComponent]];
    }
  else
    {
      [sourceFile appendFormat: @"#include \"%@\"\n\n", 
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

- (BOOL) parseHeader: (NSString *)headerPath
{
  BOOL result = NO;
  /*
  OCHeaderParser *ochp = [[OCHeaderParser alloc] initWithContentsOfFile: headerPath];
  NSArray *classes = [ochp ];
  NSArray *actions = [ochp actionList];
  NSString 
  */

  return result;
}

- (BOOL) isAction: (NSString *)name ofClass: (NSString *)className
{
  BOOL result = NO;
  NSDictionary *classInfo = [classInformation objectForKey: className];
  
  if (classInfo != nil)
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
  
  if (classInfo != nil)
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
- (NSString *) customClassForName: (NSString *)name
{
  NSString *result = [customClassMap objectForKey: name];
  return result;
}

- (NSString *) customClassForObject: (id)object
{
  NSString *name = [document nameForObject: object];
  NSString *result = [self customClassForName: name];
  NSDebugLog(@"in customClassForObject: object = %@, name = %@, result = %@, customClassMap = %@",
	     object, name, result, customClassMap);
  return result;
}

- (void) setCustomClass: (NSString *)className
              forObject: (id)object
{
  [customClassMap setObject: className forKey: object];
}

- (void) removeCustomClassForObject: (id) object
{
  [customClassMap removeObjectForKey: object];
}

- (NSMutableDictionary *) customClassMap
{
  return customClassMap;
}

- (void) setCustomClassMap: (NSMutableDictionary *)dict
{
  // copy the dictionary..
  NSDebugLog(@"dictionary = %@",dict);
  ASSIGN(customClassMap, [dict mutableCopy]);
  RETAIN(customClassMap); // released in dealloc
}

- (BOOL) isCustomClassMapEmpty
{
  return ([customClassMap count] == 0);
}

- (NSString *) nonCustomSuperClassOf: (NSString *)className
{
  NSString *result = className;
  
  if(![self isCustomClass: className] && ![className isEqual: @"NSObject"])
    {
      result = [self superClassNameForClassNamed: result];
    }
  else
    {
      // iterate up the chain until a non-custom superclass is found...
      while ([self isCustomClass: result])
	{
	  NSDebugLog(@"result = %@",result);
	  result = [self superClassNameForClassNamed: result];
	}
    }

  return result;
}

- (NSArray *) allSuperClassesOf: (NSString *)className
{
  NSMutableArray *classes = [NSMutableArray array];
  while (![className isEqualToString: @"NSObject"] && className != nil)
    {
      NSDictionary *dict = [self classInfoForClassName: className];
      if(dict != nil)
	{
	  className = [dict objectForKey: @"Super"];
	  [classes insertObject: className atIndex: 0];
	}
      else
	{
	  NSLog(@"This should never happen...  an instance without an associated class: %@",className);
	  break;
	}
    }
  return classes;
}

- (void) addActions: (NSArray *)actions forClassNamed: (NSString *)className
{
  id action = nil;
  NSEnumerator *e = [actions objectEnumerator];
  while((action = [e nextObject]))
    {
      [self addAction: action forClassNamed: className];
    }
}

- (void) addOutlets: (NSArray *)outlets forClassNamed: (NSString *)className
{
  id action = nil;
  NSEnumerator *e = [outlets objectEnumerator];
  while((action = [e nextObject]))
    {
      [self addOutlet: action forClassNamed: className];
    }
}

// There are some classes which can't be instantiated directly
// in Gorm.  These are they.. (GJC)
- (BOOL) canInstantiateClassNamed: (NSString *)className
{
  if([self isSuperclass: @"NSApplication" linkedToClass: className] || 
     [className isEqualToString: @"NSApplication"])
    {
      return NO;
    }
  else if([self isSuperclass: @"NSCell" linkedToClass: className] || 
	  [className isEqualToString: @"NSCell"])
    {
      return NO;
    }
  else if([className isEqualToString: @"NSDocument"])
    {
      return NO;
    }
  else if([className isEqualToString: @"NSDocumentController"])
    {
      return NO;
    }
  else if([className isEqualToString: @"NSFontManager"])
    {
      return NO;
    }
  else if([className isEqualToString: @"NSHelpManager"])
    {
      return NO;
    }
  else if([className isEqualToString: @"NSImage"])
    {
      return NO;
    }
  else if([self isSuperclass: @"NSMenuItem" linkedToClass: className] || 
	  [className isEqualToString: @"NSMenuItem"])
    {
      return NO;
    }
  else if([className isEqualToString: @"NSResponder"])
    {
      return NO;
    }
  else if([self isSuperclass: @"NSSound" linkedToClass: className] || 
	  [className isEqualToString: @"NSSound"])
    {
      return NO;
    }
  else if([self isSuperclass: @"NSTableColumn" linkedToClass: className] || 
	  [className isEqualToString: @"NSTableColumn"])
    {
      return NO;
    }
  else if([self isSuperclass: @"NSTableViewItem" linkedToClass: className] || 
	  [className isEqualToString: @"NSTableViewItem"])
    {
      return NO;
    }
  else if([self isSuperclass: @"NSWindow" linkedToClass: className] || 
	  [className isEqualToString: @"NSWindow"])
    {
      return NO;
    }
  else if([self isSuperclass: @"FirstResponder" linkedToClass: className] || 
	  [className isEqualToString: @"FirstResponder"])
    {
      // special case, FirstResponder.
      return NO;
    }
  
  return YES;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"<%s: %lx> = %@",
 		   GSClassNameFromObject(self), 
		   (unsigned long)self,
 		   customClassMap];
}
@end
