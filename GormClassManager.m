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
#include "GormCustomView.h"

NSString *IBClassNameChangedNotification = @"IBClassNameChangedNotification";

@interface	GormClassManager (Private)
- (NSMutableDictionary*) classInfoForClassName: (NSString*)className;
- (NSMutableDictionary*) classInfoForObject: (NSObject*)anObject;
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
      RELEASE(classInfo);
      return newClassName;
    }
  return @"";
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
      NSString			*newClassName;

      if(![classInformation objectForKey: className])
	{
	  classInfo = [[NSMutableDictionary alloc] initWithCapacity: 3];
	  
	  [classInfo setObject: outlets forKey: @"Outlets"];
	  [classInfo setObject: actions forKey: @"Actions"];
	  [classInfo setObject: superClassName forKey: @"Super"];
	  [classInformation setObject: classInfo forKey: className];
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

- (NSArray*) allClassNames
{
  NSArray *array = [NSArray arrayWithObject: @"NSObject"];
  return [array arrayByAddingObjectsFromArray:
    [[classInformation allKeys] sortedArrayUsingSelector: @selector(compare:)]];
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

- (NSMutableDictionary*) classInfoForObject: (NSObject*)obj
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
      NSLog(@"attempt to get outlets for non-existent class");
      return nil;
    }
  return [self classInfoForClassName: className];
}

- (void) dealloc
{
  RELEASE(classInformation);
  [super dealloc];
}

- (NSArray*) extraActionsForObject: (NSObject*)anObject
{
  NSMutableDictionary	*info = [self classInfoForObject: anObject];

  return [info objectForKey: @"ExtraActions"];
}

- (NSArray*) extraOutletsForObject: (NSObject*)anObject
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
	  [self loadFromFile: path];
	}
    }
  return self;
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

- (BOOL) renameClassNamed: (NSString*)oldName newName: (NSString*)name
{
  id classInfo = [classInformation objectForKey: oldName];

  if (classInfo != nil && [classInformation objectForKey: name] == nil)
    {
      RETAIN(classInfo);

      [classInformation removeObjectForKey: oldName];
      [classInformation setObject: classInfo forKey: name];

      RELEASE(classInfo);

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
  enumerator = [classInformation keyEnumerator];
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
  return YES;
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
@end


@interface GormClassInspector : IBInspector
{
  NSArray		*actions;
  NSArray		*outlets;
  NSBrowser		*browser;
  NSPopUpButton         *superClassPU;
  NSTextField           *classNameTF;
  NSMatrix              *connectionRadios;
  NSTextField           *editNameTF;
  BOOL			editClass;
  BOOL			editActions;
}

- (NSString*) identifierString: (NSString*)str;
- (void) updateButtons;
- (void) renameClass: (id)sender;
- (void) changeSuperClass: (id)sender;
@end

@implementation GormClassInspector

- (int) browser: (NSBrowser*)sender numberOfRowsInColumn: (int)column
{
  if (!editActions)
    {
      return [outlets count];
    }
  else
    {
      return [actions count];
    }
}

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (int)col
{
  if (col == 0)
    {
    }
  [editNameTF setStringValue: title];
  //[self updateButtons];
  return YES;
}

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)aCell
	   atRow: (int)row
	  column: (int)col
{
  NSString	*name;

  //if (col == 0)
  if (!editActions)
    {
      if (row >= 0 && row < [outlets count])
	{
	  name = [outlets objectAtIndex: row];
	  [aCell setStringValue: name];
	  [aCell setEnabled: YES];
	}
      else
	{
	  [aCell setStringValue: @""];
	  [aCell setEnabled: NO];
	}
    }
  else
    {
      if (row >= 0 && row < [actions count])
	{
	  name = [actions objectAtIndex: row];
	  [aCell setStringValue: name];
	  [aCell setEnabled: YES];
	}
      else
	{
	  [aCell setStringValue: @""];
	  [aCell setEnabled: NO];
	}
    }
  [aCell setLeaf: YES];
}

- (void) dealloc
{
  RELEASE(actions);
  RELEASE(outlets);
  RELEASE(okButton);
  RELEASE(revertButton);
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSRect		windowRect = NSMakeRect(0, 0, IVW, IVH-IVB);
      NSRect		rect;
      NSButtonCell	*cell;
      NSTextField	*text;
      NSMatrix		*matrix;

      window = [[NSWindow alloc] initWithContentRect: windowRect
					   styleMask: NSBorderlessWindowMask
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      rect = windowRect;
      // Class Name :
      rect.origin.y += rect.size.height - 22;
      rect.size.height = 22;
      rect.origin.x = 20;
      rect.size.width = 90-20;

      text = [[NSTextField alloc] initWithFrame: rect];
      [text setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [text setEditable: NO];
      [text setSelectable: NO];
      [text setBordered: NO];
      [text setBezeled: NO];
      [text setDrawsBackground: NO];
      [text setStringValue: @"Class name: "];
      [contents addSubview: text];
      RELEASE(text);

      rect.origin.x += 95;
      rect.size.width = 150;

      classNameTF = text = [[NSTextField alloc] initWithFrame: rect];
      [text setTarget: self];
      [text setAction: @selector(renameClass:)];
      [text setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [contents addSubview: text];
      RELEASE(text);

      // Super Class :
      rect.origin.x = 20;
      rect.origin.y -= 24;
      rect.size.height = 20;
      rect.size.width = 90-20;

      text = [[NSTextField alloc] initWithFrame: rect];
      [text setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [text setEditable: NO];
      [text setSelectable: NO];
      [text setBordered: NO];
      [text setBezeled: NO];
      [text setDrawsBackground: NO];
      [text setStringValue: @"Super class: "];
      [contents addSubview: text];
      RELEASE(text);

      rect.origin.x += 95;
      rect.size.width = 150;

      superClassPU = [[NSPopUpButton alloc] initWithFrame: rect pullsDown: NO];
      [superClassPU setTarget: self];
      [superClassPU setAction: @selector(changeSuperClass:)];
      [superClassPU setAutoresizingMask:
	NSViewWidthSizable|NSViewHeightSizable];
      [superClassPU removeAllItems];
      [superClassPU addItemWithTitle: @"superclass !"];
      [contents addSubview: superClassPU];
      RELEASE(superClassPU);

      // Outlets/Actions Radios
      rect.size = windowRect.size;
      rect.origin.x = 0;
      rect.origin.y -= 30;
      rect.size.height = 20;

      cell = [[NSButtonCell alloc] init];
      [cell setButtonType: NSRadioButton];
      [cell setBordered: NO];
      [cell setImagePosition: NSImageLeft];

      matrix = [[NSMatrix alloc] initWithFrame: rect
					  mode: NSRadioModeMatrix
				     prototype: cell
				  numberOfRows: 1
			       numberOfColumns: 2];
      RELEASE(cell);

      rect.size.width /= 2;
      [matrix setIntercellSpacing: NSZeroSize];
      [matrix setCellSize: rect.size];
      [matrix setTarget: self];
      [matrix setAutosizesCells: YES];

      cell = [matrix cellAtRow: 0 column: 0];
      [cell setTitle: @"Outlets"];
      [cell setAction: @selector(setOutlets:)];

      cell = [matrix cellAtRow: 0 column: 1];
      [cell setTitle: @"Actions"];
      [cell setAction: @selector(setActions:)];

      [matrix selectCellAtRow: 0 column: 0];
      [matrix setAutoresizingMask: (NSViewMinYMargin | NSViewWidthSizable)];
      [contents addSubview: matrix];
      connectionRadios = matrix;
      RELEASE(matrix);

      // Browser
      rect.size = windowRect.size;
      rect.size.height -= 110;
      rect.origin.y = 28;

      browser = [[NSBrowser alloc] initWithFrame: rect];
      [browser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [browser setMaxVisibleColumns: 1];
      [browser setAllowsMultipleSelection: NO];
      [browser setHasHorizontalScroller: NO];
      [browser setTitled: NO];
      [browser setDelegate: self];

      [contents addSubview: browser];
      RELEASE(browser);

      rect = windowRect;
      rect.size.height = 22;
      rect.origin.y = 0;
      editNameTF = text = [[NSTextField alloc] initWithFrame: rect];
      [contents addSubview: text];
      RELEASE(text);

      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: @"Add"];
      [okButton setEnabled: YES];

      revertButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [revertButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [revertButton setAction: @selector(revert:)];
      [revertButton setTarget: self];
      [revertButton setTitle: @"Revert"];
      [revertButton setEnabled: YES];
    }
  return self;
}

- (void) ok: (id)sender
{
  GormClassManager	*cm = [(id)[(id)NSApp activeDocument] classManager];

  if (editClass == NO)
    {
      int i;
      NSString	*name;
      NSArray   *connections;
      NSString	*cn = [object className];
      NSString  *oldName = [[browser selectedCell] stringValue];

      name = [self identifierString: [editNameTF stringValue]];

      switch (editActions)
	{ // Rename
	  case 0: // outlets

	    [editNameTF setStringValue: name];
	    if (name != nil && ![name isEqualToString: @""])
	      {
		NSLog(@"rename old outlet %@ to %@", oldName, name);
		[cm removeOutlet: oldName forObject: object];
		[cm addOutlet: name forObject: object];
		ASSIGN(outlets, [cm allOutletsForClassNamed: cn]);
		[browser reloadColumn: 0];
		
		/* Now check if this is connected to anything and make sure
		   the connection changes */
		connections = [[(id<IB>)NSApp activeDocument] allConnectors];
		for (i = 0; i < [connections count]; i++)
		  {
		    id<IBConnectors>	con = [connections objectAtIndex: i];
		    
		    if ([con class] == [NSNibOutletConnector class]
			&& [[con label] isEqual: oldName])
		      {
			[con setLabel: name];
			break;
		      }
		  }
	      }
	    break;

	  default: // actions
	    name = [name stringByAppendingString: @":"];
	    [editNameTF setStringValue: name];
	    NSLog(@"rename old outlet %@ to %@ (not implemented)", 
		  oldName, name);
	    break;
	}
    }
}

- (void) revert: (id)sender
{
  GormClassManager	*cm = [(id)[(id)NSApp activeDocument] classManager];
  NSString		*name;

  if (editClass == NO)
    {
      NSString	*cn = [object className];

      switch (editActions)
	{ // Add
	  case 0: // outlets
	    name = [self identifierString: [editNameTF stringValue]];
	    [editNameTF setStringValue: name];
	    NSLog(@"add outlet : %@", name);

	    if (name != nil && ![name isEqualToString: @""])
	      {
		NSArray		*classOutlets;

		classOutlets = [cm allOutletsForClassNamed: cn];

		if ([classOutlets containsObject: name] == NO)
		  {
		    GormClassManager	*m = [NSApp classManager];

		    [cm addOutlet: name forObject: object];
		    ASSIGN(outlets, [m allOutletsForClassNamed: cn]);
		    [browser reloadColumn: 0];
		  }
	      }
	    break;

	  default: // actions
	    name = [self identifierString: [editNameTF stringValue]];
	    name = [name stringByAppendingString: @":"];
	    [editNameTF setStringValue: name];
	    NSLog(@"add action : %@", name);

	    if (name != nil && ![name isEqualToString: @""])
	      {
		NSArray	*classActions;

		classActions = [cm allActionsForClassNamed: cn];
		if ([classActions containsObject: name] == NO)
		  {
		    GormClassManager	*m = [NSApp classManager];

		    [cm addAction: name forObject: object];
		    ASSIGN(actions, [m allActionsForClassNamed: cn]);
		    [browser reloadColumn: 0];
		  }
	      }
	    break;
	  }
    }
}

- (id) setActions: (id)sender
{
  if (editActions == NO)
    {
      editActions = YES;
      [self updateButtons];
      [browser reloadColumn: 0];
    }
  return self;
}

- (void) setObject: (id)anObject
{
  //NSLog(@"class inspector : %@", anObject);
  if (anObject != nil && anObject != object
    && [anObject isKindOfClass: [GormClassProxy class]])
    {
      NSString	*cn = [anObject className];

      ASSIGN(object, anObject);
      ASSIGN(actions, [[NSApp classManager] allActionsForClassNamed: cn]);
      ASSIGN(outlets, [[NSApp classManager] allOutletsForClassNamed: cn]);
      //NSLog(@"%@", actions);
      //[browser loadColumnZero];
      [browser reloadColumn: 0];
      [self updateButtons];
    }
}

- (id) setOutlets: (id)sender
{
  if (editActions == YES)
    {
      editActions = NO;
      [self updateButtons];
      [browser reloadColumn: 0];
    }
  return self;
}

- (void) changeSuperClass: (id)sender
{
  GormClassManager *cm = [(id)[(id)NSApp activeDocument] classManager];
  NSLog(@"change superclass");

  if ([cm setSuperClassNamed: [sender title]
    forClassNamed: [object className]] == NO)
    {
      NSRunAlertPanel(@"Error", @"Cyclic definition", @"OK", NULL, NULL);
      [self updateButtons];
    }
}

- (void) renameClass: (id)sender
{
  GormClassManager	*cm = [(id)[(id)NSApp activeDocument] classManager];
  NSString		*newName;

  NSLog(@"rename class : Attention, the current implementation won't "
    @"rename classes for objects already instantiated !");

  newName = [self identifierString: [classNameTF stringValue]];
  if (newName != nil && [newName isEqualToString: @""] == NO)
    {
      if ([cm renameClassNamed: [object className] newName: newName])
	{
	  GormClassProxy	*cp;

	  cp = [[GormClassProxy alloc] initWithClassName: newName];
	  [self setObject: cp];
	  RELEASE(cp);
	}
    }
  else
    {
      [classNameTF setStringValue: [object className]];
    }
}

/*
 * Produce identifier string byn removing illegal characters
 * and leading numerics
 */
- (NSString*) identifierString: (NSString*)str
{
  static NSCharacterSet	*illegal = nil;
  static NSCharacterSet	*numeric = nil;
  NSRange		r;
  NSMutableString	*m;

  if (illegal == nil)
    {
      illegal = [[NSCharacterSet characterSetWithCharactersInString:
	@"_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"]
	invertedSet];
      numeric = [NSCharacterSet characterSetWithCharactersInString:
	@"0123456789"];
      RETAIN(illegal); 
      RETAIN(numeric); 
    }
  if (str == nil)
    {
      return nil;
    }
  m = [str mutableCopy];
  r = [str rangeOfCharacterFromSet: illegal];
  while (r.length > 0)
    {
      [m deleteCharactersInRange: r];
      r = [m rangeOfCharacterFromSet: illegal];
    }
  r = [str rangeOfCharacterFromSet: numeric];
  while (r.length > 0 && r.location == 0)
    {
      [m deleteCharactersInRange: r];
      r = [m rangeOfCharacterFromSet: numeric];
    }
  str = [m copy];
  RELEASE(m);
  AUTORELEASE(str);

  return str;
}

- (void) updateButtons
{
  GormClassManager *cm = [(id)[(id)NSApp activeDocument] classManager];
  /*if (editClass == YES)
    {
      [okButton setTitle: @"Rename Class"];
      [revertButton setTitle: @"Add Class"];
      }*/

  if (editActions == YES)
    {
      [okButton setTitle: @"Rename Action"];
      [revertButton setTitle: @"Add Action"];
    }
  else
    {
      [okButton setTitle: @"Rename Outlet"];
      [revertButton setTitle: @"Add Outlet"];
    }

  [classNameTF setStringValue: [object className]];

  [superClassPU removeAllItems];
  //[superClassPU addItemWithTitle: @"NSObject"]; // now done in ClassManager
  [superClassPU addItemsWithTitles: [cm allClassNames]];
  [superClassPU selectItemWithTitle:
    [cm superClassNameForClassNamed: [object className]]];
}

- (BOOL) wantsButtons
{
  return YES;
}
@end

