/* GormViewAttributeInspector.h

   Copyright (C) 2026 Free Software Foundation, Inc.
   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2026
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 31 Milk St #960789, Fifth Floor, Boston,
   MA 02196 USA.
*/

#ifndef GormViewAttributesInspector_H_INCLUDE
#define GormViewAttributesInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>
GS_EXPORT_CLASS
@interface GormViewAttributesInspector : IBInspector
{
  IBOutlet id height;
  IBOutlet id identifier;
  IBOutlet id flipped;
  IBOutlet id opaque;
  IBOutlet id tag;
  IBOutlet id theClass;
  IBOutlet id width;
  IBOutlet id xpos;
  IBOutlet id ypos;
}


@end

#endif // GormViewAttributesInspector_H_INCLUDE
