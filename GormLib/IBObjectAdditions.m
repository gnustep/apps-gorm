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
// custom class support
+ (BOOL)canSubstituteForClass: (Class)origClass
{
  return YES;
}

- (void)awakeFromDocument: (id <IBDocuments>)doc
{
  // does nothing...
}

// editor
- (NSImage *)imageForViewer
{
  return nil;
}

// object labels
- (NSString *)nibLabel: (NSString *)objectName
{
  return nil;
}

// title to display in the inspector
- (NSString *)objectNameForInspectorTitle
{
  return NSStringFromClass([self class]);
}

// names of inspectors for any given class...
- (NSString*) inspectorClassName
{
  return nil;
}

- (NSString*) connectInspectorClassName
{
  return nil;
}

- (NSString*) sizeInspectorClassName
{
  return nil;
}

- (NSString*) helpInspectorClassName
{
  return nil;
}

- (NSString*) classInspectorClassName
{
  return nil;
}

// name of the editor for the current class.
- (NSString*) editorClassName
{
  return nil;
}
// list of properties not compatible with IB.
- (NSArray*) ibIncompatibleProperties
{
  return nil;
}

@end

