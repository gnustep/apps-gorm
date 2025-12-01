/* All rights reserved */

#import "GormByteCountFormatterInspector.h"

@implementation GormByteCountFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormByteCountFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormByteCountFormatterInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  NSByteCountFormatter *formatter = (NSByteCountFormatter *)object;
  
  if (formatter == nil)
    return;
  
  // Set count style from popup
  if (sender == countStyle || sender == self)
    {
      NSByteCountFormatterCountStyle style = (NSByteCountFormatterCountStyle)[[countStyle selectedItem] tag];
      [formatter setCountStyle: style];
    }
  
  // Set allowed units from popup
  if (sender == allowUnits || sender == self)
    {
      NSByteCountFormatterUnits units = (NSByteCountFormatterUnits)[[allowUnits selectedItem] tag];
      [formatter setAllowedUnits: units];
    }
  
  // Set boolean properties from checkboxes
  if (sender == allowsNumeric || sender == self)
    {
      [formatter setAllowsNonnumericFormatting: ([allowsNumeric state] == NSOnState)];
    }
  
  if (sender == includesByteCount || sender == self)
    {
      [formatter setIncludesActualByteCount: ([includesByteCount state] == NSOnState)];
    }
  
  if (sender == isAdaptive || sender == self)
    {
      [formatter setAdaptive: ([isAdaptive state] == NSOnState)];
    }
  
  if (sender == includesCount || sender == self)
    {
      [formatter setIncludesCount: ([includesCount state] == NSOnState)];
    }
  
  if (sender == includesUnit || sender == self)
    {
      [formatter setIncludesUnit: ([includesUnit state] == NSOnState)];
    }
  
  if (sender == zeroPads || sender == self)
    {
      [formatter setZeroPadsFractionDigits: ([zeroPads state] == NSOnState)];
    }
  
  [super ok: sender];
}

@end
