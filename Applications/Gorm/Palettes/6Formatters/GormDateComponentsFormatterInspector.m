/* All rights reserved */

#import "GormDateComponentsFormatterInspector.h"
#include <GormCore/GormDocument.h>
#include <InterfaceBuilder/IBApplicationAdditions.h>

@implementation GormDateComponentsFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormDateComponentsFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormDateComponentsFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSDateComponentsFormatter *formatter = (NSDateComponentsFormatter *)[object formatter];
  
  if (formatter == nil)
    {
      [allowedUnits selectItemAtIndex: 0];
      [maxUnits setIntegerValue: 0];
      [style selectItemAtIndex: 0];
      [pad setState: NSOffState];
      [dropLeading setState: NSOffState];
      [dropMiddle setState: NSOffState];
      [dropTrailing setState: NSOffState];
      [allowFractional setState: NSOffState];
      [collapseLargestUnit setState: NSOffState];
      [includeApproximation setState: NSOffState];
      [zeroFormat setStringValue: @""];
      [super revert: sender];
      return;
    }
  
  // Get current values from formatter and update UI
  
  // Set allowed units popup
  NSCalendarUnit units = [formatter allowedUnits];
  [allowedUnits selectItemWithTag: (NSInteger)units];
  
  // Set maximum unit count
  NSInteger maxCount = [formatter maximumUnitCount];
  [maxUnits setIntegerValue: maxCount];
  
  // Set formatting style
  NSDateComponentsFormatterUnitsStyle unitsStyle = [formatter unitsStyle];
  [style selectItemWithTag: (NSInteger)unitsStyle];
  
  // Set zero formatting behavior
  NSDateComponentsFormatterZeroFormattingBehavior zeroBehavior = [formatter zeroFormattingBehavior];
  
  // Extract individual zero formatting behavior flags from enum
  [dropLeading setState: (zeroBehavior & NSDateComponentsFormatterZeroFormattingBehaviorDropLeading) ? NSOnState : NSOffState];
  [dropMiddle setState: (zeroBehavior & NSDateComponentsFormatterZeroFormattingBehaviorDropMiddle) ? NSOnState : NSOffState];
  [dropTrailing setState: (zeroBehavior & NSDateComponentsFormatterZeroFormattingBehaviorDropTrailing) ? NSOnState : NSOffState];
  
  // Set pad checkbox based on whether any padding-related behavior is set
  BOOL hasPadBehavior = (zeroBehavior & (NSDateComponentsFormatterZeroFormattingBehaviorPad));
  [pad setState: hasPadBehavior ? NSOnState : NSOffState];
  
  // Set boolean properties
  [allowFractional setState: [formatter allowsFractionalUnits] ? NSOnState : NSOffState];
  [collapseLargestUnit setState: [formatter collapsesLargestUnit] ? NSOnState : NSOffState];
  [includeApproximation setState: [formatter includesApproximationPhrase] ? NSOnState : NSOffState];
  
  /*
  [includeTimeRemaining setState: [formatter includesTimeRemainingPhrase] ? NSOnState : NSOffState];
  */

  // Populate sample output with a representative components string
  NSDateComponents *components = [[NSDateComponents alloc] init];
  [components setHour: 1];
  [components setMinute: 30];
  [components setSecond: 45];
  NSString *sample = [formatter stringFromDateComponents: components];
  RELEASE(components);
  [zeroFormat setStringValue: sample ? sample : @""];

  // Seed the inspected object with the sample string if possible
  if ([object respondsToSelector: @selector(setObjectValue:)])
    {
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
  NSDateComponentsFormatter *formatter = (NSDateComponentsFormatter *)[object formatter];
  
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
  
  // Set allowed units from popup
  if (sender == allowedUnits || sender == self)
    {
      NSCalendarUnit units = (NSCalendarUnit)[[allowedUnits selectedItem] tag];
      [formatter setAllowedUnits: units];
    }
  
  // Set maximum unit count from text field
  if (sender == maxUnits || sender == self)
    {
      NSInteger maxCount = [maxUnits integerValue];
      [formatter setMaximumUnitCount: maxCount];
    }
  
  // Set formatting style from popup
  if (sender == style || sender == self)
    {
      NSDateComponentsFormatterUnitsStyle unitsStyle = (NSDateComponentsFormatterUnitsStyle)[[style selectedItem] tag];
      [formatter setUnitsStyle: unitsStyle];
    }
  
  // Build zero formatting behavior from individual checkboxes
  if (sender == pad || sender == dropLeading || sender == dropMiddle || sender == dropTrailing || sender == self)
    {
      NSDateComponentsFormatterZeroFormattingBehavior zeroBehavior = NSDateComponentsFormatterZeroFormattingBehaviorNone;
      
      if ([pad state] == NSOnState)
        {
          zeroBehavior |= NSDateComponentsFormatterZeroFormattingBehaviorPad;
        }
      
      if ([dropLeading state] == NSOnState)
        {
          zeroBehavior |= NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        }
      
      if ([dropMiddle state] == NSOnState)
        {
          zeroBehavior |= NSDateComponentsFormatterZeroFormattingBehaviorDropMiddle;
        }
      
      if ([dropTrailing state] == NSOnState)
        {
          zeroBehavior |= NSDateComponentsFormatterZeroFormattingBehaviorDropTrailing;
        }
      
      [formatter setZeroFormattingBehavior: zeroBehavior];
    }
  
  // Set zero format string from text field
  if (sender == zeroFormat || sender == self)
    {
      NSString *format = [zeroFormat stringValue];
      if (format && [format length] > 0)
        {
          // Note: There's no direct setZeroFormat: method in NSDateComponentsFormatter
        }
    }
  
  // Set boolean properties from checkboxes
  if (sender == allowFractional || sender == self)
    {
      [formatter setAllowsFractionalUnits: ([allowFractional state] == NSOnState)];
    }
  
  if (sender == collapseLargestUnit || sender == self)
    {
      [formatter setCollapsesLargestUnit: ([collapseLargestUnit state] == NSOnState)];
    }
  
  if (sender == includeApproximation || sender == self)
    {
      [formatter setIncludesApproximationPhrase: ([includeApproximation state] == NSOnState)];
    }

  /*
  if (sender == includeTimeRemaining || sender == self)
    {
      [formatter setIncludesTimeRemainingPhrase: ([includeTimeRemaining state] == NSOnState)];
    }
  */
  
  // Always update sample output when any control changes
  // Create a sample date components (1 hour, 30 minutes, 45 seconds)
  NSDateComponents *components = [[NSDateComponents alloc] init];
  [components setHour: 1];
  [components setMinute: 30];
  [components setSecond: 45];
  NSString *sample = [formatter stringFromDateComponents: components];
  RELEASE(components);
  [zeroFormat setStringValue: sample ? sample : @""];
  
  [super ok: sender];
}

@end
