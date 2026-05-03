/* ToolbarPalette

   Copyright (C) 2025 Free Software Foundation, Inc.

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: Nov 2025
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

/* All rights reserved */

#import <Foundation/Foundation.h>
#import "FormatterPalette.h"

@implementation FormatterPalette

- (void) finishInstantiate
{
  NSByteCountFormatter *byteCountFormatter = [[NSByteCountFormatter alloc] init];
  NSDateComponentsFormatter *dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
  NSDateIntervalFormatter *dateIntervalFormatter = [[NSDateIntervalFormatter alloc] init];
  NSEnergyFormatter *energyFormatter = [[NSEnergyFormatter alloc] init];
  NSISO8601DateFormatter *iso8601DateFormatter = [[NSISO8601DateFormatter alloc] init];
  NSLengthFormatter *lengthFormatter = [[NSLengthFormatter alloc] init];
  NSMassFormatter *massFormatter = [[NSMassFormatter alloc] init];
  NSMeasurementFormatter *measurementFormatter = [[NSMeasurementFormatter alloc] init];
  NSPersonNameComponentsFormatter *personNameFormatter = [[NSPersonNameComponentsFormatter alloc] init];
  
  // Set tooltips for each button
  [_byteCount setToolTip: @"NSByteCountFormatter"];
  [_dateComponents setToolTip: @"NSDateComponentsFormatter"];
  [_dateInterval setToolTip: @"NSDateIntervalFormatter"];
  [_energy setToolTip: @"NSEnergyFormatter"];
  [_iso1806date setToolTip: @"NSISO8601DateFormatter"];
  [_length setToolTip: @"NSLengthFormatter"];
  [_mass setToolTip: @"NSMassFormatter"];
  [_measurement setToolTip: @"NSMeasurementFormatter"];
  [_personNameComponents setToolTip: @"NSPersonNameComponentsFormatter"];
  
  // Associate formatters with their buttons
  [self associateObject: byteCountFormatter
                   type: IBFormatterPboardType
                   with: _byteCount];
  
  [self associateObject: dateComponentsFormatter
                   type: IBFormatterPboardType
                   with: _dateComponents];
  
  [self associateObject: dateIntervalFormatter
                   type: IBFormatterPboardType
                   with: _dateInterval];
  
  [self associateObject: energyFormatter
                   type: IBFormatterPboardType
                   with: _energy];
  
  [self associateObject: iso8601DateFormatter
                   type: IBFormatterPboardType
                   with: _iso1806date];
  
  [self associateObject: lengthFormatter
                   type: IBFormatterPboardType
                   with: _length];
  
  [self associateObject: massFormatter
                   type: IBFormatterPboardType
                   with: _mass];
  
  [self associateObject: measurementFormatter
                   type: IBFormatterPboardType
                   with: _measurement];
  
  [self associateObject: personNameFormatter
                   type: IBFormatterPboardType
                   with: _personNameComponents];
  
  [originalWindow setTitle: @"Formatters"];
}

@end
