/* Copyright (C) 2026 Free Software Foundation, Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import "Testing.h"
#import "../../6Formatters/FormatterPalette.m"

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  /* Descriptions need no palette window. Avoid loading the palette UI. */
  FormatterPalette *palette = [FormatterPalette alloc];
  NSArray *classes = [NSArray arrayWithObjects:
    @"NSByteCountFormatter", @"NSDateComponentsFormatter",
    @"NSDateIntervalFormatter", @"NSEnergyFormatter",
    @"NSISO8601DateFormatter", @"NSLengthFormatter", @"NSMassFormatter",
    @"NSMeasurementFormatter", @"NSPersonNameComponentsFormatter", nil];
  NSMutableSet *descriptions = [NSMutableSet set];
  NSString *fallback = [palette descriptionForObject:
    AUTORELEASE([NSFormatter new])];
  NSUInteger i;

  START_SET("Formatter palette descriptions")
  for (i = 0; i < [classes count]; i++)
    {
      NSString *name = [classes objectAtIndex: i];
      id formatter = AUTORELEASE([NSClassFromString(name) new]);
      NSString *description = [palette descriptionForObject: formatter];

      PASS(formatter != nil && [description length] > 0,
        "%s has a description", [name UTF8String])
      PASS(![description isEqual: fallback],
        "%s has a type-specific description", [name UTF8String])
      if (description != nil)
        [descriptions addObject: description];
    }
  PASS([descriptions count] == [classes count],
    "each formatter type has a distinct description")
  PASS([fallback length] > 0, "other formatters retain a generic description")
  PASS([palette descriptionForObject: @"not a formatter"] == nil,
    "unrelated objects have no formatter description")
  PASS([palette descriptionForObject: nil] == nil,
    "nil has no formatter description")
  END_SET("Formatter palette descriptions")

  RELEASE(palette);
  RELEASE(pool);
  return 0;
}
