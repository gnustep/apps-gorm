/* All rights reserved */

#ifndef GormEnergyFormatterInspector_H_INCLUDE
#define GormEnergyFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>
GS_EXPORT_CLASS
@interface GormEnergyFormatterInspector : IBInspector
{
  IBOutlet id unitStyle;
  IBOutlet id forFoodEnergyUse;
  IBOutlet id sampleInput;
  IBOutlet id sampleOutput;
  IBOutlet id detach;
}


@end

#endif // GormEnergyFormatterInspector_H_INCLUDE
