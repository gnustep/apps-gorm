/* All rights reserved */

#ifndef GormByteCountFormatterInspector_H_INCLUDE
#define GormByteCountFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * Inspector for NSByteCountFormatter instances.
 *
 * Provides a user interface for configuring NSByteCountFormatter properties
 * including count style, unit display options, and formatting behaviors.
 */
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
}

@end

#endif // GormByteCountFormatterInspector_H_INCLUDE
