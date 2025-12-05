/* All rights reserved */

#ifndef GormLengthFormatterInspector_H_INCLUDE
#define GormLengthFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * Inspector for NSLengthFormatter instances.
 *
 * Provides a user interface for configuring NSLengthFormatter properties
 * including unit style and person height use formatting options.
 */
@interface GormLengthFormatterInspector : IBInspector
{
  IBOutlet id forPersonHeightUse;
  IBOutlet id sampleOutput;
  IBOutlet id sampleInput;
  IBOutlet id unitStyle;
}


@end

#endif // GormLengthFormatterInspector_H_INCLUDE
