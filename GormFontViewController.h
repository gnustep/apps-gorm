/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface GormFontViewController : NSObject
{
  id fontSelector;
  id view;
}
- (void) selectFont: (id)sender;
- (id) view;
// - (void) changeFont: (id)sender;
@end
