/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "WinController.h"
GS_EXPORT_CLASS
@interface MyController : NSObject
{
  id value;
  WinController *winController;
}
- (void) buttonPressed: (id)sender;
@end
