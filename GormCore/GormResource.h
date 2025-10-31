/** <title>GormResource</title>

   <abstract>This class is a placeholder for a real resource.</abstract>
   
   Copyright (C) 2005 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: Mar 2005
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef INCLUDED_GormResource_h
#define INCLUDED_GormResource_h

#include <Foundation/Foundation.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

@class NSString, NSData;

/**
 * GormResource represents a document resource (such as an image or sound)
 * tracked by Gorm. It stores metadata like name, file type, and location,
 * along with the raw resource data when available.
 */
@interface GormResource : NSObject <IBProjectFiles>
{
  NSString        *name;
  NSString        *fileName;
  NSString        *fileType;
  BOOL            isLocalized;
  NSString        *language;
  NSString        *path;
  id<IBProjects>  project;
  BOOL            isSystemResource;
  BOOL            isInWrapper;
  NSData          *data;
}

// factory methods
/**
 * Creates and returns a resource placeholder for the specified file path.
 * The returned instance captures metadata; the raw data may be loaded later.
 */
+ (GormResource *) resourceForPath: (NSString *)path;
/**
 * Creates and returns a resource placeholder for the specified file path and
 * marks whether it resides inside the document wrapper.
 */
+ (GormResource *) resourceForPath: (NSString *)path inWrapper: (BOOL)flag;

// initialization methods
/**
 * Initializes a resource object with the given path.
 */
- (id) initWithPath: (NSString *)aPath;
/**
 * Initializes a resource object with the given path and wrapper location flag.
 */
- (id) initWithPath: (NSString *)aPath
          inWrapper: (BOOL)flag;
/**
 * Initializes a resource object with a display name and path.
 */
- (id) initWithName: (NSString *)aName
               path: (NSString *)aPath;
/**
 * Initializes a resource object with a display name, path, and wrapper flag.
 */
- (id) initWithName: (NSString *)aName
               path: (NSString *)aPath
          inWrapper: (BOOL)flag;
/**
 * Initializes a resource object with raw data, a file name, and wrapper flag.
 */
- (id) initWithData: (NSData *)aData 
       withFileName: (NSString *)aFileName 
          inWrapper: (BOOL)flag;

// instances methods
/**
 * Sets the display name of the resource.
 */
- (void) setName: (NSString *)aName;
/**
 * Returns the display name of the resource.
 */
- (NSString *) name;
/**
 * Marks whether this resource is a system resource (not saved with the
 * document).
 */
- (void) setSystemResource: (BOOL)flag;
/**
 * Returns YES if this resource is marked as a system resource; NO otherwise.
 */
- (BOOL) isSystemResource;
/**
 * Marks whether this resource resides inside the document wrapper directory.
 */
- (void) setInWrapper: (BOOL)flag;
/**
 * Returns YES if this resource resides inside the document wrapper; NO
 * otherwise.
 */
- (BOOL) isInWrapper;
/**
 * Sets the raw data for the resource.
 */
- (void) setData: (NSData *)data;
/**
 * Returns the raw data for the resource, if available.
 */
- (NSData *) data;
/**
 * Compares the receiver with another object for equality based on resource
 * identity (such as path, name, or data).
 */
- (BOOL) isEqual: (id)object;
@end

#endif
