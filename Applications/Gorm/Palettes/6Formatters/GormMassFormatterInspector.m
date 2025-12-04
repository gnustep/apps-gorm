/* All rights reserved */

#import "GormMassFormatterInspector.h"

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

- (void) ok: (id)sender
{
  // TODO: Implement saving formatter properties
  [super ok: sender];
}

@end
