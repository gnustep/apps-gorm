/* All rights reserved */

#ifndef GormDateIntervalFormatterInspector_H_INCLUDE
#define GormDateIntervalFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

@interface GormDateIntervalFormatterInspector : IBInspector
{
  IBOutlet id dateStyle;
  IBOutlet id timeStyle;
  IBOutlet id sampleEnd;
  IBOutlet id sampleStart;
  IBOutlet id output;
  IBOutlet id detach;
}


@end

#endif // GormDateIntervalFormatterInspector_H_INCLUDE
