/* All rights reserved */

#ifndef GormISO8601DateFormatterInspector_H_INCLUDE
#define GormISO8601DateFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

@interface GormISO8601DateFormatterInspector : IBInspector
{
  IBOutlet id timeZone;
  IBOutlet id fractionalSeconds;
  IBOutlet id year;
  IBOutlet id fullDate;
  IBOutlet id month;
  IBOutlet id woy;
  IBOutlet id fullTime;
  IBOutlet id day;
  IBOutlet id tz;
  IBOutlet id spaceBetweenDateAndTime;
  IBOutlet id newOutlet6;
  IBOutlet id dashSeparatorDate;
  IBOutlet id colonSeparatorTime;
  IBOutlet id colonSeparatorTZ;
}


@end

#endif // GormISO8601DateFormatterInspector_H_INCLUDE
