/* All rights reserved */

#ifndef GormDateIntervalFormatterInspector_H_INCLUDE
#define GormDateIntervalFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * Inspector for NSDateIntervalFormatter instances.
 *
 * Provides a user interface for configuring NSDateIntervalFormatter properties
 * including date style and time style for formatting date intervals.
 */
@interface GormDateIntervalFormatterInspector : IBInspector
{
  IBOutlet id dateStyle;
  IBOutlet id timeStyle;
  IBOutlet id sampleEnd;
  IBOutlet id sampleStart;
  IBOutlet id output;
}


@end

#endif // GormDateIntervalFormatterInspector_H_INCLUDE
