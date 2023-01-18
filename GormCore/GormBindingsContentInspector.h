/* All rights reserved */

#ifndef INCLUDED_GormBindingsContentInspector_H
#define INCLUDED_GormBindingsContentInspector_H

#import <InterfaceBuilder/IBInspector.h>

@interface GormBindingsContentInspector : IBInspector
{
  IBOutlet id _bindTo;
  IBOutlet id _controllerKey;
  IBOutlet id _modelKeyPath;
  IBOutlet id _raisesForNotApplicable;
  IBOutlet id _valueTransformer;
  IBOutlet id _controllerPopUp;
}

@end

#endif // INCLUDED_GormBindingsContentInspector_H
