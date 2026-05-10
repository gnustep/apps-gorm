/** <title>GormSound</title>

   <abstract>A place holder for a sound.</abstract>
   
   Copyright (C) 2001 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: Dec 2004
   
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
   31 Milk St # 960789 Boston, MA 02196 USA
*/ 

#ifndef INCLUDED_GormSound_h
#define INCLUDED_GormSound_h

#include <Foundation/Foundation.h>

#include <GormCore/GormResource.h>

@class NSString;

/**
 * GormSound represents a sound resource within a Gorm document, encapsulating sound data that can be referenced by interface elements. It manages sound file loading, storage, and provides access to the sound data for playback or export.
 */
GS_EXPORT_CLASS
@interface GormSound : GormResource

/**
 * Creates a GormSound object using the file at path.
 */
+ (GormSound*) soundForPath: (NSString *)path;

/**
 * Creates a GormSound object using the file at path, and marks it as
 * inside or outside of the .gorm/.nib wrapper.
 */
+ (GormSound*) soundForPath: (NSString *)path inWrapper: (BOOL)flag;


/**
 * Create a GormSound from raw sound data and an associated file name, and
 * indicate whether the sound resides inside the document wrapper.
 */
+ (GormSound*) soundForData: (NSData *)aData withFileName: (NSString *)aName inWrapper: (BOOL)flag;
@end

#endif
