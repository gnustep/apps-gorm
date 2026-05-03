/* inspectors - Various inspectors for formatters

   Copyright (C) 2025 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg.casamento@gmail.com>
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

#include <Foundation/Foundation.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

@implementation NSByteCountFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormByteCountFormatterInspector";
}
@end

@implementation NSDateComponentsFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormDateComponentsFormatterInspector";
}
@end

@implementation NSDateIntervalFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormDateIntervalFormatterInspector";
}
@end

@implementation NSEnergyFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormEnergyFormatterInspector";
}
@end

@implementation NSISO8601DateFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormISO8601DateFormatterInspector";
}
@end

@implementation NSLengthFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormLengthFormatterInspector";
}
@end

@implementation NSMassFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormMassFormatterInspector";
}
@end

@implementation NSMeasurementFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormMeasurementFormatterInspector";
}
@end

@implementation NSPersonNameComponentsFormatter (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormPersonNameComponentsFormatterInspector";
}
@end
