/* All rights reserved */

#ifndef INCLUDED_GormBindingsAbstractInspector_H
#define INCLUDED_GormBindingsAbstractInspector_H

#import <InterfaceBuilder/IBInspector.h>

@interface GormBindingsAbstractInspector : IBInspector
{
  IBOutlet id _bindTo;
  IBOutlet id _controllerPopUp;
  IBOutlet id _controllerKey;
  IBOutlet id _modelKeyPath;
  IBOutlet id _raisesForNotApplicable;
  IBOutlet id _valueTransformer;

  IBOutlet id _alwaysPresentsAppModalAlerts;
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
}

@end

#endif // INCLUDED_GormBindingsAbstractInspector_H
