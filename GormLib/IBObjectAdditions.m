/* IBObjectAdditions.m
 *
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * g
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <Foundation/NSObject.h>
#include <Foundation/NSObjCRuntime.h>
#include <InterfaceBuilder/IBObjectAdditions.h>

// object additions -- object adopts protocol
@implementation NSObject (IBObjectAdditions)
/**
   Returns YES if the reciever can take the
   place of the class indicated by origClass,
   NO otherwise.
 */
+ (BOOL)canSubstituteForClass: (Class)origClass
{
  return YES;
}

/**
   This method is called on all objects after
   they are loaded into the IBDocuments object.
 */
- (void)awakeFromDocument: (id <IBDocuments>)doc
{
  // does nothing...
}

/**
   Used to provide an image which represents the
   reciever.
 */
- (NSImage *)imageForViewer
{
  return nil;
}

/**
   Name for the reciever in the name table.
 */
- (NSString *)nibLabel: (NSString *)objectName
{
  return nil;
}

/**
   Title to display in the inspector.
 */
- (NSString *)objectNameForInspectorTitle
{
  return NSStringFromClass([self class]);
}

/**
   Class name of the attributes inspector for the reciever.
 */
- (NSString*) inspectorClassName
{
  return nil;
}

/**
   Class name of the connection inspector for the reciever.
 */
- (NSString*) connectInspectorClassName
{
  return nil;
}

/**
   Class name of the size inspector for the reciever.
 */
- (NSString*) sizeInspectorClassName
{
  return nil;
}

/**
   Class name of the help inspector for the receiver.
 */
- (NSString*) helpInspectorClassName
{
  return nil;
}

/**
   Class name of the class inspector for the receiver.
 */
- (NSString*) classInspectorClassName
{
  return nil;
}

/**
   Class name of the editor
 */
- (NSString*) editorClassName
{
  return nil;
}

/**
   Lists all properties if this object not compatible with IB.
 */
- (NSArray*) ibIncompatibleProperties
{
  return nil;
}

@end

