/* All Rights reserved */

#include <AppKit/AppKit.h>

/**
 * GormFontViewController coordinates a small font selection UI used by Gorm
 * to preview and apply fonts in inspectors and editors.
 */
@interface GormFontViewController : NSObject
{
  id fontSelector;
  id view;
  id encodeButton;
}
/**
 * Returns the shared font view controller instance used across the
 * application.
 */
+ (GormFontViewController *) sharedGormFontViewController;
/**
 * Returns a converted font suitable for the UI, based on the provided font
 * (for example, applying size/style substitutions).
 */
- (NSFont *) convertFont: (NSFont *)oldFont;
/**
 * Action: present or update font selection based on the sender.
 */
- (void) selectFont: (id)sender;
/**
 * Returns the view managed by this controller.
 */
- (id) view;
// - (void) changeFont: (id)sender;
@end
