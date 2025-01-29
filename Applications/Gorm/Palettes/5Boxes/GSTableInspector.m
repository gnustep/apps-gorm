/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GSTableInspector.h"
#include <GNUstepGUI/GSTable.h>

@implementation GSTable (IBObjectAdditions)
- (NSString *)inspectorClassName
{
  return @"GSTableInspector";
}
@end

@implementation GSTableInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GSTableInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GSTableInspector");
      return nil;
    }
  return self;
}

- (void) ok: (id)sender
{
  [super ok: sender];
  NSLog(@"Testing...");

  if(sender == matrix)
    {
      [object setXBorder: [[sender cellAtIndex: 0] intValue]];
      [object setYBorder: [[sender cellAtIndex: 1] intValue]];
      [object setMinXBorder: [[sender cellAtIndex: 2] intValue]];
      [object setMaxXBorder: [[sender cellAtIndex: 3] intValue]];
      [object setMinYBorder: [[sender cellAtIndex: 4] intValue]];
      [object setMaxYBorder: [[sender cellAtIndex: 5] intValue]];
    }
}

- (void) setObject: (id)anobject
{
  [super setObject: anobject];
}
@end
