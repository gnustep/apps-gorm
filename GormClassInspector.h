/** <title>GormClassInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: September 2002

   This file is part of GNUstep.

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

/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <InterfaceBuilder/IBInspector.h>

@class GormClassManager;

@interface GormClassInspector : IBInspector
{
  // outlets
  id actionTable; 
  id addAction;
  id addOutlet;
  id classField;
  id outletTable;
  id removeAction;
  id removeOutlet;
  id tabView;

  // internal vars
  NSString *currentClass;
  id theobject;
  id actionData;
  id outletData;

  // class manager..
  GormClassManager *classManager;
}
- (void) addAction: (id)sender;
- (void) removeAction: (id)sender;
- (void) addOutlet: (id)sender;
- (void) removeOutlet: (id)sender;
- (void) select: (id)sender;
- (NSString *) _currentClass;
@end
