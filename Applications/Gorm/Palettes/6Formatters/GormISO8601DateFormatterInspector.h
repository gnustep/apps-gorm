/* All rights reserved */

#ifndef GormISO8601DateFormatterInspector_H_INCLUDE
#define GormISO8601DateFormatterInspector_H_INCLUDE

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * Inspector for NSISO8601DateFormatter instances.
 *
 * Provides a user interface for configuring NSISO8601DateFormatter properties
 * including format options for year, month, day, week of year, time zone,
 * fractional seconds, separators, and spacing between date and time components.
 */
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
  IBOutlet id internetDateAndTime;
  IBOutlet id dashSeparatorDate;
  IBOutlet id colonSeparatorTime;
  IBOutlet id colonSeparatorTZ;
  IBOutlet id sampleInput;
  IBOutlet id sampleOutput;
}


@end

#endif // GormISO8601DateFormatterInspector_H_INCLUDE
