/** <title>GormSound</title>

   <abstract>A place holder for a sound.</abstract>
   
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

#ifndef INCLUDED_GormSound_h
#define INCLUDED_GormSound_h

#include <Foundation/NSObject.h>
#include <GormCore/GormResource.h>

@class NSString;

@interface GormSound : GormResource
{
}

+ (GormSound*) soundForPath: (NSString *)path;
+ (GormSound*) soundForPath: (NSString *)path inWrapper: (BOOL)flag;
- (NSString *)inspectorClassName;
@end

#endif
