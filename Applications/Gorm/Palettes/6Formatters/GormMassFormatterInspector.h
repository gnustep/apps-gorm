/* All rights reserved */

#ifndef GormMassFormatterInspector_H_INCLUDE
#define GormMassFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * Inspector for NSMassFormatter instances.
 *
 * Provides a user interface for configuring NSMassFormatter properties
 * including unit style and person mass use formatting options.
 */
@interface GormMassFormatterInspector : IBInspector
{
  IBOutlet id unitStyle;
  IBOutlet id output;
  IBOutlet id forPersonMassUse;
  IBOutlet id sample;
}


@end

#endif // GormMassFormatterInspector_H_INCLUDE
