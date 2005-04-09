/* IBResourceManager.m
 *
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2005
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

#include <InterfaceBuilder/IBResourceManager.h>
#include <InterfaceBuilder/IBPalette.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSNotification.h> 
#include <Foundation/NSString.h>
#include <AppKit/NSPasteboard.h>

/**
 * Notification sent when a resource manager class is added to /removed from 
 * the registry.
 */
NSString *IBResourceManagerRegistryDidChangeNotification = @"IBResourceManagerRegistryDidChangeNotification";

static NSMapTable *_resourceManagers = NULL;

@implementation IBResourceManager : NSObject

+ (void) _createTable
{
  if(_resourceManagers == NULL)
    {
      _resourceManagers = NSCreateMapTable(NSObjectMapKeyCallBacks,
					   NSObjectMapValueCallBacks, 
					   2);
    }
}

/**
 * Register the given class as a resource mananger.
 */
+ (void) registerResourceManagerClass: (Class)managerClass
{
  NSMutableArray *list = NSMapGet(_resourceManagers, NULL);

  if(list == NULL)
    {
      list = [NSMutableArray array];
      NSMapInsert(_resourceManagers, NULL, list);
    }
  [list addObject: managerClass];

  // notify.
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: IBResourceManagerRegistryDidChangeNotification
    object: nil];
}

/**
 * Register the given class as a resource manager for the frameworks in the array.
 */ 
+ (void) registerResourceManagerClass: (Class)managerClass 
                        forFrameworks: (NSArray *)frameworks
{
  NSEnumerator *en = [frameworks objectEnumerator];
  NSString *fw = nil;

  [self _createTable];
  while((fw = [en nextObject]) != nil)
    {
      NSMutableArray *list = NSMapGet(_resourceManagers, fw);
      if(list == NULL)
	{
	  list = [NSMutableArray array];
	  NSMapInsert(_resourceManagers, fw, list);
	}
      [list addObject: managerClass];
    }

  // notify 
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: IBResourceManagerRegistryDidChangeNotification
    object: nil];
}


/**
 * Return an array of classes for the given framework.
 */
+ (NSArray *) registeredResourceManagerClassesForFramework: (NSString *)framework
{
  return (NSArray *)(NSMapGet(_resourceManagers, framework));
}

/**
 * Returns YES, if the pasteboard contains a type the resource 
 * manager can accept.
 */
- (BOOL) acceptsResourcesFromPasteboard: (NSPasteboard *)pboard
{
  NSArray *types = [pboard types];
  NSArray *resourcePbTypes = [self resourcePasteboardTypes]; 
  id obj = [types firstObjectCommonWithArray: resourcePbTypes];
  BOOL result = NO;

  if(obj != nil)
    {
      result = YES;
    }

  return result;
}

/**
 * Add an array of resources.
 */
- (void) addResources: (NSArray *)resourceList
{
  // abstract...
}

/**
 * Add resoures from the pasteboard.  Invokes the 
 * acceptsResourcesFromPasteboard: method to determine 
 * if the resources will be added.
 */
- (void) addResourcesFromPasteboard: (NSPasteboard *)pboard
{
  // abstract...
}

/**
 * Called by an external application when a file owned by 
 * the GUI builder is modified.  Override this method in a
 * subclass to take some special action.
 */
- (void) application: (NSString *) appName didModifyFileAtPath: (NSString *)path
{
  // does nothing.
}

/**
 * Returns the document with which this resource manager is
 * associated.
 */
- (id<IBDocuments>) document
{
  return document;
}

/**
 * Instantiate the resource manager with the given 
 * document object.
 */
- (id) initWithDocument: (id<IBDocuments>)doc
{
  if((self = [super init]) != nil)
    {
      document = doc;
    }
  return self;
}

/**
 * Deallocate the object.
 */
- (void) dealloc
{
  document = nil;
  [super dealloc];
}

/**
 * Returns YES, if this resource manager is non-modifiable.
 */
- (BOOL) isReadOnly;
{
  return NO;
}

/**
 * Called by an external application when the a file
 * is added.  Override in subclass to take action.
 */
- (void) project: (id<IBProjects>)proj didAddFile: (id<IBProjectFiles>)file
{
}

/**
 * Called by an external application when the a file
 * changes localization.   Override this method in a subclass
 * to take some special action.
 */
- (void) project: (id<IBProjects>)proj didChangeLocalizationOfFile: (id<IBProjectFiles>)file
{
}

/**
 * Called by an external application when a file
 * is removed.  Override this in a subclass to take
 * some special action.
 */
- (void) project: (id<IBProjects>)proj didRemoveFile: (id<IBProjectFiles>)file
{
  // does nothing
}

/**
 * Returns a list of resource file types this manager can accept.  Default 
 * implementation returns nil.
 */
- (NSArray *) resourceFileTypes
{
  return nil;
}

/**
 * Returns a list of pasteboard types this manager can accept.  Default
 * implementation returns nil.
 */
- (NSArray *) resourcePasteboardTypes
{
  return [NSArray arrayWithObjects: IBObjectPboardType, IBViewPboardType, nil];
}

/**
 * Returns the associated resources for the objects.
 */
- (NSArray *) resourcesForObjects: (NSArray *)objs;
{
  return nil;
}

/**
 * Writes resources to the document path.
 */
- (void) writeToDocumentPath: (NSString *)path
{
  // does nothing.
}

@end
