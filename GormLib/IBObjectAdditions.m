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
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * g
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <Foundation/NSObject.h>
#include <Foundation/NSObjCRuntime.h>
#include <InterfaceBuilder/IBObjectAdditions.h>

// object additions -- object adopts protocol
@implementation NSObject (_IBObjectAdditions)

// Return yes if origClass can substitute for current class, otherwise NO.
+ (BOOL)canSubstituteForClass: (Class)origClass
{
  return NO;
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
   Name for the reciever in the name table.
 */
- (NSString *)nibLabel: (NSString *)objectName
{
  NSString *label = [NSString stringWithFormat: @"%@(%@)",
			      [self className],
			      objectName];
  return label;
}

/**
   Title to display in the inspector.
 */
- (NSString *)objectNameForInspectorTitle
{
  return [self className];
}

/**
   Lists all properties if this object not compatible with IB.
 */
- (NSArray*) ibIncompatibleProperties
{
  return nil;
}

@end

