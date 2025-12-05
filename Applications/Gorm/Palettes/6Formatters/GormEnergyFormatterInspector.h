/* All rights reserved */

#ifndef GormEnergyFormatterInspector_H_INCLUDE
#define GormEnergyFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * Inspector for NSEnergyFormatter instances.
 *
 * Provides a user interface for configuring NSEnergyFormatter properties
 * including unit style and food energy use formatting options.
 */
@interface GormEnergyFormatterInspector : IBInspector
{
  IBOutlet id unitStyle;
  IBOutlet id forFoodEnergyUse;
  IBOutlet id sampleInput;
  IBOutlet id sampleOutput;
}


@end

#endif // GormEnergyFormatterInspector_H_INCLUDE
