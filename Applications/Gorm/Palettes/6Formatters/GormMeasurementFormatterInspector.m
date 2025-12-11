/* Implementation of class GormMeasurementFormatterInspector
   Copyright (C) 2025 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 30-11-2025

   This file is part of GNUstep.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "GormMeasurementFormatterInspector.h"

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
    return;
  
  // Get current values from formatter and update UI
  
  // Set unit style popup
  NSFormattingUnitStyle style = [formatter unitStyle];
  [unitStyle selectItemWithTag: (NSInteger)style];
  
  // Set natural scale checkbox
  BOOL useNaturalScale = [[formatter numberFormatter] usesSignificantDigits];
  [naturalScale setState: useNaturalScale ? NSOnState : NSOffState];
  
  // Set provided unit text field (display as string for reference)
  NSUnit *unit = [formatter providedUnit];
  [providedUnit setStringValue: unit ? [unit symbol] : @""];
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSMeasurementFormatter *formatter = (NSMeasurementFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
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
