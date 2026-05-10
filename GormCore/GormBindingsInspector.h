/** <title>GormBindingsInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: September 2002

   This file is part of GNUstep.

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

/* All Rights reserved */

#ifndef INCLUDED_GormBindingsInspector_h
#define INCLUDED_GormBindingsInspector_h

#import <AppKit/AppKit.h>
#import <InterfaceBuilder/InterfaceBuilder.h>
GS_EXPORT_CLASS
@interface GormBindingsInspector : IBInspector
{
  // outlets
  IBOutlet NSPopUpButton *_bindingsPopUp;
  IBOutlet NSBox *_containerView;

  IBInspector *_inspectorObject;
  NSMutableArray *_bindingsArray;

  NSUInteger _selectedInspectorIndex;
}

- (IBAction) selectInspector: (id)sender;

@end

#endif // INCLUDED_GormBindingsInspector_h
