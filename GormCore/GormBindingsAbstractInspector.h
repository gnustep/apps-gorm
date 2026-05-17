/* GormBindingsAbstractInspector.h

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

#ifndef INCLUDED_GormBindingsAbstractInspector_H
#define INCLUDED_GormBindingsAbstractInspector_H

#import <InterfaceBuilder/IBInspector.h>

// Top level placeholder IDs
#define NS_APP_ID -3

GS_EXPORT_CLASS
@interface GormBindingsAbstractInspector : IBInspector
{
  IBOutlet id _bindTo;
  IBOutlet id _sourcePopUp;
  IBOutlet id _controllerKey;
  IBOutlet id _modelKeyPath;
  IBOutlet id _valueTransformer;

  IBOutlet id _alwaysPresentAppModalAlerts;
  IBOutlet id _raisesForNotApplicableKeys;
  IBOutlet id _validatesImmediately;

  IBOutlet id _multipleValuesPlaceholder;
  IBOutlet id _noSelectionPlaceholder;
  IBOutlet id _notApplicablePlaceholder;
  IBOutlet id _nullPlaceholder;

  IBOutlet id _multipleValuesTitle;
  IBOutlet id _noSelectionTitle;
  IBOutlet id _notApplicableTitle;
  IBOutlet id _nullTitle;
  IBOutlet id _valueTransformerTitle;
  IBOutlet id _bindingsPopUp;

  id _source;
  NSString *_bindingName;
}

- (void) setBindingName: (NSString *)bindings;

@end

#endif // INCLUDED_GormBindingsAbstractInspector_H
