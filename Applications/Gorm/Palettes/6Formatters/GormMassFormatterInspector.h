/* All rights reserved */

#ifndef GormMassFormatterInspector_H_INCLUDE
#define GormMassFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>
GS_EXPORT_CLASS
@interface GormMassFormatterInspector : IBInspector
{
  IBOutlet id unitStyle;
  IBOutlet id output;
  IBOutlet id forPersonMassUse;
  IBOutlet id sample;
  IBOutlet id detach;
}


@end

#endif // GormMassFormatterInspector_H_INCLUDE
