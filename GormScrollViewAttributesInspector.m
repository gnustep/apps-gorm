/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GormScrollViewAttributesInspector.h"
#include <InterfaceBuilder/IBObjectAdditions.h>

@implementation NSScrollView (IBObjectAdditions)
- (NSString *) inspectorClassName
{
  return @"GormScrollViewAttributesInspector";
}
@end

@implementation GormScrollViewAttributesInspector

- (void) colorSelected: (id)sender
{
  /* insert your code here */
}


- (void) verticalSelected: (id)sender
{
  /* insert your code here */
}


- (void) horizontalSelected: (id)sender
{
  /* insert your code here */
}


- (void) borderSelected: (id)sender
{
  /* insert your code here */
}

@end
