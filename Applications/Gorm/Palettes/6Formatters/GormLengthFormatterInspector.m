/* All rights reserved */

#import "GormLengthFormatterInspector.h"

@implementation GormLengthFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormLengthFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormLengthFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSLengthFormatter *formatter = (NSLengthFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Get current values from formatter and update UI
  
  // Set unit style popup
  NSFormattingUnitStyle style = [formatter unitStyle];
  [unitStyle selectItemWithTag: (NSInteger)style];
  
  // Set person height use checkbox
  BOOL heightUse = [formatter isForPersonHeightUse];
  [forPersonHeightUse setState: heightUse ? NSOnState : NSOffState];
  
  // Set sample input to a default value (1.75 meters)
  [sampleInput setDoubleValue: 1.75];
  
  // Generate sample output
  NSString *sample = [formatter stringFromMeters: 1.75];
  [sampleOutput setStringValue: sample ? sample : @""];
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSLengthFormatter *formatter = (NSLengthFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Set unit style from popup
  if (sender == unitStyle || sender == self)
    {
      NSFormattingUnitStyle style = (NSFormattingUnitStyle)[[unitStyle selectedItem] tag];
      [formatter setUnitStyle: style];
    }
  
  // Set person height use from checkbox
  if (sender == forPersonHeightUse || sender == self)
    {
      BOOL heightUse = ([forPersonHeightUse state] == NSOnState);
      [formatter setForPersonHeightUse: heightUse];
    }
  
  // Always update sample output
  double meters = [sampleInput doubleValue];
  NSString *sample = [formatter stringFromMeters: meters];
  [sampleOutput setStringValue: sample ? sample : @""];
  
  [super ok: sender];
}

@end
