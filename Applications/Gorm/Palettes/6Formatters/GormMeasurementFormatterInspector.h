/* All rights reserved */

#ifndef GormMeasurementFormatterInspector_H_INCLUDE
#define GormMeasurementFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>
GS_EXPORT_CLASS
@interface GormMeasurementFormatterInspector : IBInspector
{
  IBOutlet id unitStyle;
  IBOutlet id naturalScale;
  IBOutlet id providedUnit;
  IBOutlet id temperatureWithoutUnit;
  IBOutlet id revert;
  IBOutlet id detach;
}


@end

#endif // GormMeasurementFormatterInspector_H_INCLUDE
