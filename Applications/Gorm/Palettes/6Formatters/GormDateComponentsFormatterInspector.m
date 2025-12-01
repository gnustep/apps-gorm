/* All rights reserved */

#import "GormDateComponentsFormatterInspector.h"

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

- (void) ok: (id)sender
{
  // TODO: Implement saving formatter properties
  [super ok: sender];
}

@end
