/* All rights reserved */

#ifndef GormDateComponentsFormatterInspector_H_INCLUDE
#define GormDateComponentsFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * Inspector for NSDateComponentsFormatter instances.
 *
 * Provides a user interface for configuring NSDateComponentsFormatter properties
 * including allowed units, formatting style, maximum unit count, zero formatting
 * behavior, and padding options.
 */
@interface GormDateComponentsFormatterInspector : IBInspector
{
  IBOutlet id allowFractional;
  IBOutlet id allowedUnits;
  IBOutlet id collapseLargestUnit;
  IBOutlet id includeApproximation;
  IBOutlet id includeTimeRemaining;
  IBOutlet id maxUnits;
  IBOutlet id pad;
  IBOutlet id dropTrailing;
  IBOutlet id dropMiddle;
  IBOutlet id dropLeading;
  IBOutlet id style;
  IBOutlet id zeroFormat;
}


@end

#endif // GormDateComponentsFormatterInspector_H_INCLUDE
