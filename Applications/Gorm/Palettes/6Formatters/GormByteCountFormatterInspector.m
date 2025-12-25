/* All rights reserved */

#import "GormByteCountFormatterInspector.h"
#include <GormCore/GormDocument.h>
#include <InterfaceBuilder/IBApplicationAdditions.h>

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

- (void) revert: (id)sender
{
  NSByteCountFormatter *formatter = (NSByteCountFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Get current values from formatter and update UI
  
  // Set count style popup
  NSByteCountFormatterCountStyle style = [formatter countStyle];
  [countStyle selectItemWithTag: (NSInteger)style];
  
  // Set allowed units popup
  NSByteCountFormatterUnits units = [formatter allowedUnits];
  [allowUnits selectItemWithTag: (NSInteger)units];
  
  // Set boolean properties
  [allowsNumeric setState: [formatter allowsNonnumericFormatting] ? NSOnState : NSOffState];
  [includesByteCount setState: [formatter includesActualByteCount] ? NSOnState : NSOffState];
  [isAdaptive setState: [formatter isAdaptive] ? NSOnState : NSOffState];
  [includesCount setState: [formatter includesCount] ? NSOnState : NSOffState];
  [includesUnit setState: [formatter includesUnit] ? NSOnState : NSOffState];
  [zeroPads setState: [formatter zeroPadsFractionDigits] ? NSOnState : NSOffState];
  
  // Set sample input to a default value (1024000000 bytes = ~1GB)
  [sampleInput setDoubleValue: 1024000000.0];
  
  // Generate sample output
  NSString *sample = [formatter stringFromByteCount: 1024000000];
  [sampleOutput setStringValue: sample ? sample : @""];
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSByteCountFormatter *formatter = (NSByteCountFormatter *)[object formatter];
  
  if (formatter == nil)
    return;

  if (sender == detach)
    {
      id<IB> ibApp = (id<IB>)[NSApp delegate];
      GormDocument *document = (GormDocument *)[ibApp activeDocument];

      [document detachObject: formatter closeEditor: YES];
      if ([object respondsToSelector: @selector(setFormatter:)])
        {
          [object setFormatter: nil];
        }
      [document setSelectionFromEditor: nil];
      return;
    }
  
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
  
  // Always update sample output when any control changes
  long long byteCount = (long long)[sampleInput doubleValue];
  NSString *sample = [formatter stringFromByteCount: byteCount];
  [sampleOutput setStringValue: sample ? sample : @""];
  
  [super ok: sender];
}

@end
