/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "Gorm.h"

@class GormClassManager;

@interface GormCustomClassInspector : IBInspector
{
  id browser;
  GormClassManager *_classManager;
  id _currentSelection;
  NSString *_currentSelectionClassName;
}
- (void) select: (id)sender;
@end
