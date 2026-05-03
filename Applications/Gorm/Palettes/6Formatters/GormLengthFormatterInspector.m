/* All rights reserved */

#import "GormLengthFormatterInspector.h"
#include <GormCore/GormDocument.h>
#include <InterfaceBuilder/IBApplicationAdditions.h>

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
    {
      [unitStyle selectItemAtIndex: 0];
      [forPersonHeightUse setState: NSOffState];
      [sampleInput setDoubleValue: 0.0];
      [sampleOutput setStringValue: @""];
      [super revert: sender];
      return;
    }
  
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

  // Seed the inspected object with a representative sample value if possible
  if ([object respondsToSelector: @selector(setObjectValue:)])
    {
      NSNumber *value = [NSNumber numberWithDouble: 1.75];
      id current = nil;
      if ([object respondsToSelector: @selector(objectValue)])
        {
          current = [object objectValue];
        }
      [object setObjectValue: (current != nil) ? current : value];
    }
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSLengthFormatter *formatter = (NSLengthFormatter *)[object formatter];
  
  if (formatter == nil)
    return;

  if (sender == detach)
    {
      id<IB> ibApp = (id<IB>)[NSApp delegate];
      GormDocument *document = (GormDocument *)[ibApp activeDocument];

      if (formatter != nil)
        {
          [document detachObject: formatter closeEditor: YES];
        }

      if ([object respondsToSelector: @selector(setFormatter:)])
        {
          [object setFormatter: nil];
        }

      [document setSelectionFromEditor: nil];
      [self setObject: [self object]];
      return;
    }
  
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
