/** <title>GormImage</title>

   <abstract>This class is a placeholder for a real image.</abstract>
   
   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: Dec 2004
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef INCLUDED_GormImage_h
#define INCLUDED_GormImage_h

#include <Foundation/NSObject.h>

@class NSString, NSImage;

@interface GormImage : NSObject
{
  NSString *name;
  NSString *path;
  NSImage  *image;
  NSImage  *smallImage;
  BOOL     isSystemImage;
  BOOL     isInWrapper; 
}

+ (GormImage *) imageForPath: (NSString *)path;
- (id) initWithPath: (NSString *)aPath;
- (id) initWithName: (NSString *)aName
               path: (NSString *)aPath;
- (void) setImageName: (NSString *)aName;
- (NSString *) imageName;
- (void) setImagePath: (NSString *)aPath;
- (NSString *) imagePath;
- (void) setSystemImage: (BOOL)flag;
- (BOOL) isSystemImage;
- (void) setInWrapper: (BOOL)flag;
- (BOOL) isInWrapper;
- (NSString *)inspectorClassName;
- (NSImage *)image;
- (NSImage *)normalImage;
@end

#endif
