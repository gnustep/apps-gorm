/* All rights reserved */

#import "GormMassFormatterInspector.h"
#include <GormCore/GormDocument.h>
#include <InterfaceBuilder/IBApplicationAdditions.h>

@implementation GormMassFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormMassFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormMassFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSMassFormatter *formatter = (NSMassFormatter *)[object formatter];
  
  if (formatter == nil)
    {
      [unitStyle selectItemAtIndex: 0];
      [forPersonMassUse setState: NSOffState];
      [sample setDoubleValue: 0.0];
      [output setStringValue: @""];
      [super revert: sender];
      return;
    }
  
  // Get current values from formatter and update UI
  
  // Set unit style popup
  NSFormattingUnitStyle style = [formatter unitStyle];
  [unitStyle selectItemWithTag: (NSInteger)style];
  
  // Set person mass use checkbox
  BOOL massUse = [formatter isForPersonMassUse];
  [forPersonMassUse setState: massUse ? NSOnState : NSOffState];
  
  // Set sample input to a default value (70 kilograms)
  [sample setDoubleValue: 70.0];
  
  // Generate sample output
  NSString *sampleText = [formatter stringFromKilograms: 70.0];
  [output setStringValue: sampleText ? sampleText : @""];

  // Seed the inspected object with a representative sample value if possible
  if ([object respondsToSelector: @selector(setObjectValue:)])
    {
      NSNumber *value = [NSNumber numberWithDouble: 70.0];
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
  NSMassFormatter *formatter = (NSMassFormatter *)[object formatter];
  
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
  
  // Set person mass use from checkbox
  if (sender == forPersonMassUse || sender == self)
    {
      BOOL massUse = ([forPersonMassUse state] == NSOnState);
      [formatter setForPersonMassUse: massUse];
    }
  
  // Always update sample output
  double kilograms = [sample doubleValue];
  NSString *sampleText = [formatter stringFromKilograms: kilograms];
  [output setStringValue: sampleText ? sampleText : @""];
  
  [super ok: sender];
}

@end
