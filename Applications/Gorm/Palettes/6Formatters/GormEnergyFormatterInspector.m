/* All rights reserved */

#import "GormEnergyFormatterInspector.h"

@implementation GormEnergyFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormEnergyFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormEnergyFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSEnergyFormatter *formatter = (NSEnergyFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Get current values from formatter and update UI
  
  // Set unit style popup
  NSFormattingUnitStyle style = [formatter unitStyle];
  [unitStyle selectItemWithTag: (NSInteger)style];
  
  // Set food energy use checkbox
  BOOL foodUse = [formatter isForFoodEnergyUse];
  [forFoodEnergyUse setState: foodUse ? NSOnState : NSOffState];
  
  // Set sample input to a default value (1000 joules)
  [sampleInput setDoubleValue: 1000.0];
  
  // Generate sample output
  NSString *sample = [formatter stringFromJoules: 1000.0];
  [sampleOutput setStringValue: sample ? sample : @""];
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSEnergyFormatter *formatter = (NSEnergyFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Set unit style from popup
  if (sender == unitStyle || sender == self)
    {
      NSFormattingUnitStyle style = (NSFormattingUnitStyle)[[unitStyle selectedItem] tag];
      [formatter setUnitStyle: style];
    }
  
  // Set food energy use from checkbox
  if (sender == forFoodEnergyUse || sender == self)
    {
      BOOL foodUse = ([forFoodEnergyUse state] == NSOnState);
      [formatter setForFoodEnergyUse: foodUse];
    }
  
  // Always update sample output
  double joules = [sampleInput doubleValue];
  NSString *sample = [formatter stringFromJoules: joules];
  [sampleOutput setStringValue: sample ? sample : @""];
  
  [super ok: sender];
}

@end
