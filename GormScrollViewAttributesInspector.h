/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <InterfaceBuilder/IBInspector.h>

@interface GormScrollViewAttributesInspector : IBInspector
{
  id pageContext;
  id lineAmount;
  id color;
  id verticalScroll;
  id horizontalScroll;
  id borderMatrix;
}
- (void) colorSelected: (id)sender;
- (void) verticalSelected: (id)sender;
- (void) horizontalSelected: (id)sender;
- (void) borderSelected: (id)sender;
@end
