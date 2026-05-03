/* All rights reserved */

#import "GormMeasurementFormatterInspector.h"
#include <GormCore/GormDocument.h>
#include <InterfaceBuilder/IBApplicationAdditions.h>

@implementation GormMeasurementFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormMeasurementFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormMeasurementFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSMeasurementFormatter *formatter = (NSMeasurementFormatter *)[object formatter];
  
  if (formatter == nil)
    {
      [unitStyle selectItemAtIndex: 0];
      [naturalScale setState: NSOffState];
      [providedUnit setStringValue: @""];
      [super revert: sender];
      return;
    }
  
  // Get current values from formatter and update UI
  
  // Set unit style popup
  NSFormattingUnitStyle style = [formatter unitStyle];
  [unitStyle selectItemWithTag: (NSInteger)style];
  
  // Set natural scale checkbox
  BOOL useNaturalScale = [[formatter numberFormatter] usesSignificantDigits];
  [naturalScale setState: useNaturalScale ? NSOnState : NSOffState];
  
  // Set provided unit text field (display as string for reference)
  // NSUnit *unit = [formatter providedUnit];
  // [providedUnit setStringValue: unit ? [unit symbol] : @""];

  // Seed the inspected object with a sample measurement string if possible
  if ([object respondsToSelector: @selector(setObjectValue:)])
    {
      NSMeasurement *measurement = [[NSMeasurement alloc] initWithDoubleValue: 1.0
                                                                          unit: [NSUnitLength meters]];
      NSString *sample = [formatter stringFromMeasurement: measurement];
      RELEASE(measurement);

      id current = nil;
      if ([object respondsToSelector: @selector(objectValue)])
        {
          current = [object objectValue];
        }
      [object setObjectValue: (current != nil) ? current : sample];
    }
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSMeasurementFormatter *formatter = (NSMeasurementFormatter *)[object formatter];
  
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
  
  // Set natural scale from checkbox
  if (sender == naturalScale || sender == self)
    {
      BOOL useNaturalScale = ([naturalScale state] == NSOnState);
      NSNumberFormatter *numFormatter = [formatter numberFormatter];
      if (numFormatter == nil)
        {
          numFormatter = [[NSNumberFormatter alloc] init];
          [formatter setNumberFormatter: numFormatter];
          RELEASE(numFormatter);
        }
      [numFormatter setUsesSignificantDigits: useNaturalScale];
    }
  
  [super ok: sender];
}

@end
