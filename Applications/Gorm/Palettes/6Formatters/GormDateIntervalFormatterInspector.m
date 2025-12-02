/* All rights reserved */

#import "GormDateIntervalFormatterInspector.h"

@implementation GormDateIntervalFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormDateIntervalFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormDateIntervalFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSDateIntervalFormatter *formatter = (NSDateIntervalFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Get current values from formatter and update UI
  
  // Set date style popup
  NSDateIntervalFormatterStyle dateStyleValue = [formatter dateStyle];
  [dateStyle selectItemWithTag: (NSInteger)dateStyleValue];
  
  // Set time style popup
  NSDateIntervalFormatterStyle timeStyleValue = [formatter timeStyle];
  [timeStyle selectItemWithTag: (NSInteger)timeStyleValue];
  
  // Set sample dates to current date/time if empty
  NSDate *now = [NSDate date];
  NSDate *later = [now dateByAddingTimeInterval: 3600]; // 1 hour later
  
  [sampleStart setObjectValue: now];
  [sampleEnd setObjectValue: later];
  
  // Generate sample output
  NSString *sample = [formatter stringFromDate: now toDate: later];
  [output setStringValue: sample ? sample : @""];
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSDateIntervalFormatter *formatter = (NSDateIntervalFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Set date style from popup
  if (sender == dateStyle || sender == self)
    {
      NSDateIntervalFormatterStyle style = (NSDateIntervalFormatterStyle)[[dateStyle selectedItem] tag];
      [formatter setDateStyle: style];
    }
  
  // Set time style from popup
  if (sender == timeStyle || sender == self)
    {
      NSDateIntervalFormatterStyle style = (NSDateIntervalFormatterStyle)[[timeStyle selectedItem] tag];
      [formatter setTimeStyle: style];
    }
  
  // Update sample output when styles change
  if (sender == dateStyle || sender == timeStyle || sender == sampleStart || sender == sampleEnd || sender == self)
    {
      NSDate *startDate = [sampleStart objectValue];
      NSDate *endDate = [sampleEnd objectValue];
      
      if (startDate && endDate)
        {
          NSString *sample = [formatter stringFromDate: startDate toDate: endDate];
          [output setStringValue: sample ? sample : @""];
        }
    }
  
  [super ok: sender];
}

@end
