/* All rights reserved */

#ifndef GormByteCountFormatterInspector_H_INCLUDE
#define GormByteCountFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

@interface GormByteCountFormatterInspector : IBInspector
{
  IBOutlet id countStyle;
  IBOutlet id allowUnits;
  IBOutlet id allowsNumeric;
  IBOutlet id includesByteCount;
  IBOutlet id isAdaptive;
  IBOutlet id includesCount;
  IBOutlet id includesUnit;
  IBOutlet id zeroPads;
  IBOutlet id sampleInput;
  IBOutlet id sampleOutput;
  IBOutlet id detach;
}


@end

#endif // GormByteCountFormatterInspector_H_INCLUDE
