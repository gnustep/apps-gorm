/* All Rights reserved */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

/**
 * GormNSSplitViewInspector provides controls for editing NSSplitView
 * attributes in the inspector, such as orientation and divider style.
 */
@interface GormNSSplitViewInspector : IBInspector
{
  id orientation;
  id divider;
}
@end
