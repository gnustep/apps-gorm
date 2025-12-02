/* All rights reserved */

#import "GormISO8601DateFormatterInspector.h"

@implementation GormISO8601DateFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormISO8601DateFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormISO8601DateFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSISO8601DateFormatter *formatter = (NSISO8601DateFormatter *)object;
  
  if (formatter == nil)
    return;
  
  // Get current format options from formatter
  NSISO8601DateFormatOptions options = [formatter formatOptions];
  
  // Update checkboxes based on format options
  [year setState: (options & NSISO8601DateFormatWithYear) ? NSOnState : NSOffState];
  [month setState: (options & NSISO8601DateFormatWithMonth) ? NSOnState : NSOffState];
  [day setState: (options & NSISO8601DateFormatWithDay) ? NSOnState : NSOffState];
  [woy setState: (options & NSISO8601DateFormatWithWeekOfYear) ? NSOnState : NSOffState];
  [fullDate setState: (options & NSISO8601DateFormatWithFullDate) ? NSOnState : NSOffState];
  [fullTime setState: (options & NSISO8601DateFormatWithFullTime) ? NSOnState : NSOffState];
  [tz setState: (options & NSISO8601DateFormatWithTimeZone) ? NSOnState : NSOffState];
  [fractionalSeconds setState: (options & NSISO8601DateFormatWithFractionalSeconds) ? NSOnState : NSOffState];
  [spaceBetweenDateAndTime setState: (options & NSISO8601DateFormatWithSpaceBetweenDateAndTime) ? NSOnState : NSOffState];
  [dashSeparatorDate setState: (options & NSISO8601DateFormatWithDashSeparatorInDate) ? NSOnState : NSOffState];
  [colonSeparatorTime setState: (options & NSISO8601DateFormatWithColonSeparatorInTime) ? NSOnState : NSOffState];
  [colonSeparatorTZ setState: (options & NSISO8601DateFormatWithColonSeparatorInTimeZone) ? NSOnState : NSOffState];
  
  // Set time zone display
  NSTimeZone *tz = [formatter timeZone];
  [timeZone setStringValue: tz ? [tz name] : @""];
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSISO8601DateFormatter *formatter = (NSISO8601DateFormatter *)object;
  
  if (formatter == nil)
    return;
  
  // Build format options from checkboxes
  NSISO8601DateFormatOptions options = 0;
  
  if ([year state] == NSOnState)
    options |= NSISO8601DateFormatWithYear;
  if ([month state] == NSOnState)
    options |= NSISO8601DateFormatWithMonth;
  if ([day state] == NSOnState)
    options |= NSISO8601DateFormatWithDay;
  if ([woy state] == NSOnState)
    options |= NSISO8601DateFormatWithWeekOfYear;
  if ([fullDate state] == NSOnState)
    options |= NSISO8601DateFormatWithFullDate;
  if ([fullTime state] == NSOnState)
    options |= NSISO8601DateFormatWithFullTime;
  if ([tz state] == NSOnState)
    options |= NSISO8601DateFormatWithTimeZone;
  if ([fractionalSeconds state] == NSOnState)
    options |= NSISO8601DateFormatWithFractionalSeconds;
  if ([spaceBetweenDateAndTime state] == NSOnState)
    options |= NSISO8601DateFormatWithSpaceBetweenDateAndTime;
  if ([dashSeparatorDate state] == NSOnState)
    options |= NSISO8601DateFormatWithDashSeparatorInDate;
  if ([colonSeparatorTime state] == NSOnState)
    options |= NSISO8601DateFormatWithColonSeparatorInTime;
  if ([colonSeparatorTZ state] == NSOnState)
    options |= NSISO8601DateFormatWithColonSeparatorInTimeZone;
  
  [formatter setFormatOptions: options];
  
  [super ok: sender];
}

@end
